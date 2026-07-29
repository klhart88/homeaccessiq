-- ============================================================
-- IHCDA First Step -- whole-county targeted-area exemption
-- ============================================================
-- Gap #2 from the handoff doc: IHCDA's own program guide states
-- that a purchase in one of the 30 whole-county-targeted counties
-- gets the same first-time-buyer waiver that veteran status gets.
-- Only the veteran exemption existed until now.
--
-- Mirrors the existing veteran-exemption pattern exactly:
--   a rule that PASSES sets exempts_rule_id -> waives the
--   first_time_buyer buyer_status rule. No engine code changes
--   needed -- evaluateRules() in matchingEngine.js already applies
--   exempts_rule_id generically for any rule_type, and already
--   excludes exemption-trigger rows from ever counting as an
--   unmet reason on their own.
--
-- Scope note: this covers ONLY the 30 whole-county-targeted
-- counties. It deliberately does NOT cover the 17 counties with a
-- targeted TRACT (including Marion) -- that's the separate,
-- still-open tract-level geocoding gap (gap #1), which this
-- migration does not attempt to solve.
--
-- Safe to re-run: checks for an existing identical exemption row
-- before inserting, so running this twice won't create a duplicate.
-- ============================================================

do $$
declare
  v_program_id   uuid;
  v_ftb_rule_id  uuid;
  v_next_order   int;
  v_existing_id  uuid;
  v_allowed_values jsonb := jsonb_build_array(
    '18013', -- Brown
    '18023', -- Clinton
    '18025', -- Crawford
    '18027', -- Daviess
    '18029', -- Dearborn
    '18031', -- Decatur
    '18041', -- Fayette
    '18047', -- Franklin
    '18049', -- Fulton
    '18055', -- Greene
    '18071', -- Jackson
    '18073', -- Jasper
    '18077', -- Jefferson
    '18083', -- Knox
    '18093', -- Lawrence
    '18103', -- Miami
    '18115', -- Ohio
    '18117', -- Orange
    '18119', -- Owen
    '18121', -- Parke
    '18123', -- Perry
    '18125', -- Pike
    '18139', -- Rush
    '18143', -- Scott
    '18145', -- Shelby
    '18147', -- Spencer
    '18165', -- Vermillion
    '18167', -- Vigo
    '18175', -- Washington
    '18177'  -- Wayne
  );
begin
  -- Find the program by name. Adjust the ILIKE pattern if your
  -- programs.name value differs from "IHCDA First Step".
  select id into v_program_id
  from programs
  where name ilike '%IHCDA%First Step%'
  limit 1;

  if v_program_id is null then
    raise exception 'Could not find IHCDA First Step in programs.name -- check the actual value and adjust this script before re-running';
  end if;

  -- Find the existing first-time-buyer requirement for this program.
  -- This is the SAME rule the veteran-status row already exempts.
  select id into v_ftb_rule_id
  from program_eligibility_rules
  where program_id = v_program_id
    and rule_type = 'buyer_status'
    and rule_config ->> 'status_required' = 'first_time_buyer'
  limit 1;

  if v_ftb_rule_id is null then
    raise exception 'Could not find a buyer_status/first_time_buyer rule for IHCDA First Step -- check existing rule rows before re-running';
  end if;

  -- Idempotency check: don't insert a duplicate if this has already run.
  select id into v_existing_id
  from program_eligibility_rules
  where program_id = v_program_id
    and rule_type = 'geographic_scope'
    and exempts_rule_id = v_ftb_rule_id
    and rule_config ->> 'location_field' = 'purchase'
  limit 1;

  if v_existing_id is not null then
    raise notice 'Targeted-county exemption rule already exists (id=%) -- skipping insert', v_existing_id;
    return;
  end if;

  select coalesce(max(evaluation_order), 0) + 10 into v_next_order
  from program_eligibility_rules
  where program_id = v_program_id;

  insert into program_eligibility_rules (
    program_id, rule_type, rule_config, exempts_rule_id, evaluation_order
  )
  values (
    v_program_id,
    'geographic_scope',
    jsonb_build_object(
      'scope_level', 'county',
      'location_field', 'purchase',
      'allowed_values', v_allowed_values
    ),
    v_ftb_rule_id,
    v_next_order
  );

  raise notice 'Inserted targeted-county exemption rule for program % exempting rule %', v_program_id, v_ftb_rule_id;
end $$;
