-- ============================================================
-- IHCDA Step Down + Next Home -- new programs
-- ============================================================
-- Source (primary): IHCDA's own Universal Program Guide
-- (in.gov/ihcda/files/HOD-Universal-Program-Guide-Final.pdf,
-- Feb 2026) and IHCDA's own program summary pages
-- (in.gov/ihcda/homebuyers).
--
-- Both share the SAME county income/acquisition data already
-- loaded and refreshed for First Step -- the source PDF itself is
-- explicitly titled "Limits apply to First Step, Step Down, and
-- Next Home." No new dollar figures to source; this clones First
-- Step's existing rule structure onto two new programs rather
-- than re-researching numbers.
--
-- Step Down: rate-only, NO down payment assistance at all --
-- "a rate-only program for qualifying first-time homebuyers"
-- (IHCDA's own summary). Same first-time-buyer-unless-targeted-
-- area-or-veteran rule as First Step (identical wording in the
-- Universal Guide). Flagged with program_type = 'rate_reduction'
-- so the UI can visually distinguish it from every DPA-dollar
-- program around it (per Kelvin: still worth including given
-- current rate environment, just needs to stand out as a
-- different kind of benefit).
--
-- Next Home: 3.5% non-forgivable DPA (IHCDA's own summary page).
-- Confirmed NO first-time-buyer restriction at all -- "The
-- Mortgagor does not have to be a first-time homebuyer" (stated
-- identically in both the Next Home FHA and Conventional program
-- guides). Uses the same income/acquisition limits (confirmed by
-- the Next Home Conventional guide's own executive summary:
-- "must use income and acquisition limits").
-- ============================================================

do $$
declare
  v_first_step_id uuid;
  v_income_table_name text;
  v_income_targeted_table_name text;
  v_acq_table_name text;
  v_acq_targeted_table_name text;
  v_targeted_tract_source_url text;
  v_whole_county_config jsonb;

  v_step_down_id uuid;
  v_step_down_ftb_rule_id uuid;
  v_next_home_id uuid;
  v_income_basis text;
  v_income_comparator text;
begin
  -- ------------------------------------------------------------
  -- Discover First Step's existing structure -- clone, don't
  -- re-guess or hardcode any of this.
  -- ------------------------------------------------------------
  select id into v_first_step_id from programs where name ilike '%IHCDA%First Step%' limit 1;
  if v_first_step_id is null then
    raise exception 'Could not find IHCDA First Step -- check programs.name';
  end if;

  select rule_config ->> 'lookup_table', rule_config ->> 'targeted_lookup_table', rule_config ->> 'targeted_tract_source_url',
         rule_config ->> 'income_basis', rule_config ->> 'comparator'
  into v_income_table_name, v_income_targeted_table_name, v_targeted_tract_source_url,
       v_income_basis, v_income_comparator
  from program_eligibility_rules
  where program_id = v_first_step_id and rule_type = 'income_threshold'
  limit 1;

  select rule_config ->> 'lookup_table', rule_config ->> 'targeted_lookup_table'
  into v_acq_table_name, v_acq_targeted_table_name
  from program_eligibility_rules
  where program_id = v_first_step_id and rule_type = 'financial_underwriting'
    and rule_config ->> 'field' = 'purchase_price_cap'
  limit 1;

  -- Clone the exact whole-county-targeted geographic_scope config
  -- (the 30-county allowed_values list) from First Step's own
  -- exemption row, rather than retyping the FIPS list a fourth time.
  select rule_config into v_whole_county_config
  from program_eligibility_rules
  where program_id = v_first_step_id and rule_type = 'geographic_scope'
    and rule_config ->> 'location_field' = 'purchase'
    and exempts_rule_id is not null
    and not (rule_config ? 'targeted_lookup_table')  -- the whole-county one, not the tract one
  limit 1;

  if v_income_table_name is null or v_acq_table_name is null or v_whole_county_config is null then
    raise exception 'Could not fully resolve First Step''s existing rule structure -- check its rule_config shapes before re-running';
  end if;

  raise notice 'Cloning from First Step: income_table=%, acq_table=%, targeted_income_table=%, targeted_acq_table=%',
    v_income_table_name, v_acq_table_name, v_income_targeted_table_name, v_acq_targeted_table_name;

  -- ------------------------------------------------------------
  -- Step Down
  -- ------------------------------------------------------------
  insert into programs (name, administering_entity, program_type, description, source_url, funding_status)
  values (
    'IHCDA Step Down',
    'Indiana Housing and Community Development Authority',
    'rate_reduction',
    'A below-market interest rate on your first mortgage -- no down payment assistance is provided with this program. First-time buyer required unless purchasing in a HUD-designated targeted census tract, an eligible veteran, or an entire targeted county.',
    'https://www.in.gov/ihcda/files/HOD-Universal-Program-Guide-Final.pdf',
    'open'
  )
  returning id into v_step_down_id;

  -- first_time_buyer requirement (same as First Step)
  insert into program_eligibility_rules (program_id, rule_type, rule_config, evaluation_order)
  values (
    v_step_down_id, 'buyer_status',
    jsonb_build_object('status_required', 'first_time_buyer', 'lookback_years', 3),
    0
  )
  returning id into v_step_down_ftb_rule_id;

  -- veteran exemption
  insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
  values (
    v_step_down_id, 'buyer_status',
    jsonb_build_object('status_required', 'veteran'),
    v_step_down_ftb_rule_id, 10
  );

  -- whole-county-targeted exemption (cloned config from First Step)
  insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
  values (
    v_step_down_id, 'geographic_scope',
    v_whole_county_config,
    v_step_down_ftb_rule_id, 20
  );

  -- income limit (same table + same targeted-tract config as First Step)
  insert into program_eligibility_rules (program_id, rule_type, rule_config, evaluation_order)
  values (
    v_step_down_id, 'income_threshold',
    jsonb_build_object(
      'lookup_table', v_income_table_name,
      'income_basis', v_income_basis,
      'comparator', v_income_comparator,
      'targeted_lookup_table', v_income_targeted_table_name,
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', v_targeted_tract_source_url
    ),
    30
  );

  -- acquisition/purchase-price cap (same table + targeted config)
  insert into program_eligibility_rules (program_id, rule_type, rule_config, evaluation_order)
  values (
    v_step_down_id, 'financial_underwriting',
    jsonb_build_object(
      'field', 'purchase_price_cap',
      'lookup_table', v_acq_table_name,
      'targeted_lookup_table', v_acq_targeted_table_name,
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', v_targeted_tract_source_url
    ),
    40
  );

  raise notice 'Step Down created: %', v_step_down_id;

  -- ------------------------------------------------------------
  -- Next Home -- NO first_time_buyer rule at all (confirmed:
  -- available to first-time AND repeat buyers unconditionally).
  -- ------------------------------------------------------------
  insert into programs (name, administering_entity, program_type, description, source_url, funding_status)
  values (
    'IHCDA Next Home',
    'Indiana Housing and Community Development Authority',
    'deferred_loan',
    'Down payment assistance of 3.5% of the purchase price as a non-forgivable second mortgage. Available to first-time AND repeat homebuyers -- no first-time-buyer requirement. Full balance due when the first mortgage terminates, the property stops being the primary residence, is sold, refinanced (outside an IHCDA refinance program), or a HELOC is taken.',
    'https://www.in.gov/ihcda/homebuyers/',
    'open'
  )
  returning id into v_next_home_id;

  insert into program_eligibility_rules (program_id, rule_type, rule_config, evaluation_order)
  values (
    v_next_home_id, 'income_threshold',
    jsonb_build_object(
      'lookup_table', v_income_table_name,
      'income_basis', v_income_basis,
      'comparator', v_income_comparator,
      'targeted_lookup_table', v_income_targeted_table_name,
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', v_targeted_tract_source_url
    ),
    0
  );

  insert into program_eligibility_rules (program_id, rule_type, rule_config, evaluation_order)
  values (
    v_next_home_id, 'financial_underwriting',
    jsonb_build_object(
      'field', 'purchase_price_cap',
      'lookup_table', v_acq_table_name,
      'targeted_lookup_table', v_acq_targeted_table_name,
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', v_targeted_tract_source_url
    ),
    10
  );

  raise notice 'Next Home created: %', v_next_home_id;
end $$;
