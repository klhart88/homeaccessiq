-- ============================================================
-- IHCDA targeted census tracts -- Hancock fix + 2024 corroboration
-- ============================================================
-- Kelvin found CENSUS-TRACTS-FOR-TARGETED-AREAS_4_16_24.pdf on
-- IHCDA's own site -- a document dated April 16, 2024, four years
-- newer than the 2020 one originally loaded.
--
-- Compared tract-by-tract, county-by-county against the 2020 data
-- already in targeted_census_tracts: every one of the 16 counties
-- already loaded is IDENTICAL between the two documents (Allen's
-- 25 tracts, Lake's 47, Marion's 98, all unchanged across 4 years).
-- That's strong evidence the original data was correct all along --
-- census tract boundaries only get redrawn once a decade (next is
-- 2030), so 4 years of zero drift is expected for genuinely stable
-- data, not a sign of staleness.
--
-- The ONE real difference: Hancock County had ZERO tracts in the
-- 2020 document (the gap flagged in the previous migration) but
-- has exactly one tract in this 2024 document: 4104.01. Adding it
-- here -- this was the only county with a genuine data gap, and
-- it's now filled with real, sourced data.
--
-- Note: this 2024 document also lists Randolph County (tract
-- 9516.00), same as the 2020 one did, even though Randolph isn't
-- marked "+" in the current 2026 income limits. Consistent across
-- both documents, not a new discrepancy -- not loaded, out of
-- scope for the current 17-county set, same reasoning as the extra
-- counties excluded from the original 2020 load.
--
-- This does NOT flip targeted_tract_data_status to "confirmed" --
-- that still requires an actual human confirmation from IHCDA
-- (the planned phone call), since this is still self-sourced
-- corroboration, not an official answer. But the caveat message in
-- matchingEngine.js is updated to reflect the much stronger
-- evidence now available.
-- ============================================================

do $$
declare
  v_source_url text := 'https://www.in.gov/ihcda/files/CENSUS-TRACTS-FOR-TARGETED-AREAS_4_16_24.pdf';
  v_source_date date := '2024-04-16';
begin
  -- Hancock: the one real gap, now filled.
  insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
  values ('IN', '18059', '18059410401', v_source_url, v_source_date)
  on conflict (state_code, tract_geoid) do nothing;

  -- Update source metadata on all previously-loaded rows to reflect
  -- the 2024 corroboration (same tract, now backed by two
  -- independent snapshots 4 years apart instead of one).
  update targeted_census_tracts
  set source_url = v_source_url,
      source_last_updated = v_source_date,
      last_verified_date = current_date
  where county_fips != '18059'; -- Hancock already set correctly above

  raise notice 'Hancock tract added (4104.01); source metadata refreshed for all 17 counties to reflect 2024 corroboration.';
end $$;

-- Update the rule_config pointer to reference the newer,
-- corroborating 2024 document instead of the 2020 one.
do $$
declare
  v_program_id uuid;
begin
  select id into v_program_id from programs where name ilike '%IHCDA%First Step%' limit 1;
  if v_program_id is null then
    raise exception 'Could not find IHCDA First Step program';
  end if;

  update program_eligibility_rules
  set rule_config = rule_config || jsonb_build_object(
    'targeted_tract_source_url', 'https://www.in.gov/ihcda/files/CENSUS-TRACTS-FOR-TARGETED-AREAS_4_16_24.pdf'
  )
  where program_id = v_program_id
    and rule_config ? 'targeted_lookup_table';

  raise notice 'Updated targeted_tract_source_url on IHCDA rules to point at the 2024 document';
end $$;
