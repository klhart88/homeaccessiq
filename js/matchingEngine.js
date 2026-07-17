// ============================================
// HomeAccessIQ — Matching Engine
// (Net-new — the core value proposition)
//
// DESIGN DECISION: evaluation happens client-side (JS), not as
// a Postgres function. Program/rule counts are small for v1
// (manual curation, dozens of programs, not thousands), and
// jsonb-shaped rule_config is far easier to debug in JS than in
// PL/pgSQL. Revisit as a Postgres RPC only if this becomes a
// real performance bottleneck.
//
// rule_config shapes by rule_type (what actually gets stored in
// program_eligibility_rules.rule_config):
//
//   income_threshold:
//     { comparator: 'lte'|'gte', income_basis: 'household'|'borrower_only',
//       lookup_table: '<geo_lookup_tables.table_name>' }
//     (ami_percent is descriptive metadata for humans reading the
//     rule; the actual dollar threshold comes from geo_lookup_values,
//     since the same AMI% maps to different dollar amounts per county)
//
//   geographic_scope:
//     { scope_level: 'state'|'county'|'city', allowed_values: [...] }
//     (designated_zone/geofence scope is NOT handled yet — flagged
//     in evaluateGeographicScope as needsVerification)
//
//   occupation_membership:
//     { allowed_tags: [...matches occupation_taxonomy.tag], match_mode: 'any_of' }
//
//   buyer_status:
//     { status_required: 'first_time_buyer'|'veteran'|'disability', lookback_years? }
//     (lookback_years is documentation for the intake form, not
//     evaluated here — is_first_time_buyer is self-reported already
//     accounting for it)
//
//   employer_criteria:
//     { employer_location_required: 'same_state'|<state_code>,
//       min_hours_per_week?, min_tenure_days?, job_tier_min? }
//     (job_tier_min has no corresponding buyer field yet — flagged
//     as needsVerification, not a hard block)
//
//   financial_underwriting:
//     { field: 'credit_score'|'dti_ratio'|'purchase_price_cap',
//       comparator: 'gte'|'lte', value?, lookup_table? }
//     (value is used directly for credit_score/dti_ratio; for
//     purchase_price_cap, lookup_table is used instead, same
//     reasoning as income_threshold above)
// ============================================

import { supabaseClient } from './supabaseClient.js';

// ---------- Public entry point ----------

// buyerProfile: a full row from buyer_profiles (already fetched;
// RLS ensures it's the caller's own profile).
// Returns an array of match results, one per active program:
//   { program, isMatch, unmetReasons: [...], needsVerification: [...] }
export async function matchProgramsForBuyer(buyerProfile) {
  const programs = await fetchActivePrograms();
  const results = [];

  for (const program of programs) {
    const rules = await fetchRulesForProgram(program.id);
    const evaluation = await evaluateRules(rules, buyerProfile);
    results.push({
      program,
      isMatch: evaluation.isMatch,
      unmetReasons: evaluation.unmetReasons,
      needsVerification: evaluation.needsVerification
    });
  }

  return results;
}

// ---------- Data fetching ----------

async function fetchActivePrograms() {
  const { data, error } = await supabaseClient
    .from('programs')
    .select('*')
    .neq('funding_status', 'exhausted');

  if (error) throw new Error(`Could not load programs: ${error.message}`);
  return data;
}

async function fetchRulesForProgram(programId) {
  const { data, error } = await supabaseClient
    .from('program_eligibility_rules')
    .select('*')
    .eq('program_id', programId)
    .order('evaluation_order', { ascending: true });

  if (error) throw new Error(`Could not load rules: ${error.message}`);
  return data;
}

// Looks up a threshold value keyed by geography. household_size
// is optional -- some lookup tables don't vary by it, in which
// case pass null and rows with a null household_size will match.
async function fetchGeoLookupValue(tableName, stateCode, countyFips, householdSize) {
  let query = supabaseClient
    .from('geo_lookup_values')
    .select('numeric_value, geo_lookup_tables!inner(table_name)')
    .eq('geo_lookup_tables.table_name', tableName)
    .eq('state_code', stateCode);

  if (countyFips) query = query.eq('county_fips', countyFips);
  if (householdSize) query = query.eq('household_size', householdSize);

  const { data, error } = await query.maybeSingle();
  if (error) {
    console.warn(`Geo lookup failed for ${tableName}/${stateCode}:`, error);
    return null;
  }
  return data ? data.numeric_value : null;
}

// ---------- Rule evaluation ----------

// Evaluates all of a program's rules against a buyer profile,
// respecting exemption chains (a rule can waive another rule it
// references via exempts_rule_id -- e.g. veteran status exempting
// the first-time-buyer requirement).
async function evaluateRules(rules, buyerProfile) {
  const ruleResults = new Map(); // rule.id -> { passed, reason, needsVerification }
  const unmetReasons = [];
  const needsVerification = [];

  // Rules are already ordered by evaluation_order, so a rule's
  // exemption target (if earlier in the list) has already been
  // evaluated by the time we reach rules that depend on it.
  for (const rule of rules) {
    const result = await evaluateSingleRule(rule, buyerProfile);
    ruleResults.set(rule.id, result);
  }

  // Apply exemptions: if rule A passed and exempts rule B, B's
  // outcome is overridden to "passed" regardless of its own result.
  for (const rule of rules) {
    if (rule.exempts_rule_id && ruleResults.get(rule.id)?.passed) {
      const exempted = ruleResults.get(rule.exempts_rule_id);
      if (exempted && !exempted.passed) {
        exempted.passed = true;
        exempted.reason = null;
        exempted.exemptedBy = rule.rule_type;
      }
    }
  }

  for (const rule of rules) {
    const result = ruleResults.get(rule.id);
    if (result.needsVerification) {
      needsVerification.push(`${rule.rule_type}: ${result.needsVerification}`);
    }
    if (!result.passed) {
      unmetReasons.push(result.reason || `${rule.rule_type} not satisfied`);
    }
  }

  return {
    isMatch: unmetReasons.length === 0,
    unmetReasons,
    needsVerification
  };
}

async function evaluateSingleRule(rule, buyerProfile) {
  const config = rule.rule_config;

  switch (rule.rule_type) {
    case 'buyer_status':
      return evaluateBuyerStatus(config, buyerProfile);

    case 'occupation_membership':
      return evaluateOccupationMembership(config, buyerProfile);

    case 'geographic_scope':
      return evaluateGeographicScope(config, buyerProfile);

    case 'income_threshold':
      return evaluateIncomeThreshold(config, buyerProfile);

    case 'financial_underwriting':
      return evaluateFinancialUnderwriting(config, buyerProfile);

    case 'employer_criteria':
      return evaluateEmployerCriteria(config, buyerProfile);

    default:
      return { passed: false, reason: `Unknown rule_type: ${rule.rule_type}` };
  }
}

function evaluateBuyerStatus(config, buyer) {
  const map = {
    first_time_buyer: buyer.is_first_time_buyer,
    veteran: buyer.veteran_status,
    disability: buyer.disability_status
  };
  const value = map[config.status_required];
  if (value === undefined) {
    return { passed: false, reason: `Unrecognized status_required: ${config.status_required}` };
  }
  return {
    passed: !!value,
    reason: value ? null : `Requires ${config.status_required.replace(/_/g, ' ')}`
  };
}

function evaluateOccupationMembership(config, buyer) {
  if (!buyer.occupation_tag) {
    return { passed: false, reason: 'No occupation on file' };
  }
  const passed = (config.allowed_tags || []).includes(buyer.occupation_tag);
  return { passed, reason: passed ? null : "Occupation not in program's eligible list" };
}

function evaluateGeographicScope(config, buyer) {
  if (config.scope_level === 'designated_zone') {
    return {
      passed: false,
      needsVerification: 'Designated-zone geofence matching not yet implemented -- verify manually'
    };
  }

  const buyerValue = {
    state: buyer.purchase_state,
    county: buyer.purchase_county_fips,
    city: buyer.purchase_city
  }[config.scope_level];

  const passed = (config.allowed_values || []).includes(buyerValue);
  return { passed, reason: passed ? null : `Purchase location outside program's ${config.scope_level} scope` };
}

async function evaluateIncomeThreshold(config, buyer) {
  const buyerIncome = config.income_basis === 'borrower_only'
    ? buyer.borrower_only_income
    : buyer.household_income;

  if (buyerIncome == null) {
    return { passed: false, needsVerification: `Missing ${config.income_basis} income on buyer profile` };
  }

  const limit = await fetchGeoLookupValue(
    config.lookup_table,
    buyer.purchase_state,
    buyer.purchase_county_fips,
    buyer.household_size
  );

  if (limit == null) {
    return { passed: false, needsVerification: `No income limit found for ${config.lookup_table} in this county` };
  }

  const passed = config.comparator === 'gte' ? buyerIncome >= limit : buyerIncome <= limit;
  return { passed, reason: passed ? null : `Income does not meet the ${config.income_basis} limit for this area` };
}

async function evaluateFinancialUnderwriting(config, buyer) {
  if (config.field === 'purchase_price_cap') {
    if (buyer.target_purchase_price == null) {
      return { passed: false, needsVerification: 'Target purchase price not on file' };
    }
    if (!config.lookup_table) {
      return { passed: false, reason: 'Program rule missing lookup_table for purchase_price_cap' };
    }
    const cap = await fetchGeoLookupValue(config.lookup_table, buyer.purchase_state, buyer.purchase_county_fips, null);
    if (cap == null) {
      return { passed: false, needsVerification: 'No purchase price cap found for this county' };
    }
    const passed = buyer.target_purchase_price <= cap;
    return { passed, reason: passed ? null : "Target purchase price exceeds this area's cap" };
  }

  const buyerFieldMap = {
    credit_score: buyer.credit_score,
    dti_ratio: buyer.dti_ratio
  };
  const buyerValue = buyerFieldMap[config.field];

  if (buyerValue == null) {
    return { passed: false, needsVerification: `Missing ${config.field} on buyer profile` };
  }

  const passed = config.comparator === 'gte' ? buyerValue >= config.value : buyerValue <= config.value;
  return { passed, reason: passed ? null : `${config.field} does not meet program requirement` };
}

function evaluateEmployerCriteria(config, buyer) {
  if (!buyer.employer_name) {
    return { passed: false, reason: 'No employer on file' };
  }

  if (config.employer_location_required === 'same_state' && buyer.employer_state !== buyer.purchase_state) {
    return { passed: false, reason: 'Employer must be located in the purchase state' };
  }
  if (config.employer_location_required && config.employer_location_required !== 'same_state'
      && buyer.employer_state !== config.employer_location_required) {
    return { passed: false, reason: `Employer must be located in ${config.employer_location_required}` };
  }

  if (config.min_hours_per_week) {
    if (buyer.employer_hours_per_week == null) {
      return { passed: false, needsVerification: 'Hours/week not on file' };
    }
    if (buyer.employer_hours_per_week < config.min_hours_per_week) {
      return { passed: false, reason: `Requires at least ${config.min_hours_per_week} hrs/week` };
    }
  }

  if (config.min_tenure_days) {
    if (!buyer.employer_start_date) {
      return { passed: false, needsVerification: 'Employer start date not on file' };
    }
    const tenureDays = Math.floor((Date.now() - new Date(buyer.employer_start_date)) / (1000 * 60 * 60 * 24));
    if (tenureDays < config.min_tenure_days) {
      return { passed: false, reason: `Requires ${config.min_tenure_days} days' tenure (has ${tenureDays})` };
    }
  }

  if (config.job_tier_min) {
    return { passed: true, needsVerification: `Job tier requirement (${config.job_tier_min}) not verifiable from profile -- confirm manually` };
  }

  return { passed: true, reason: null };
}
