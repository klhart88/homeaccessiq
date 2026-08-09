-- ============================================================
-- IHCDA First Step -- targeted CENSUS TRACT infrastructure
-- (Gap #1 from the handoff: the 17 counties with a targeted
-- tract, not the 30 whole-county-targeted counties already
-- handled.)
-- ============================================================
--
-- IMPORTANT -- READ BEFORE RUNNING:
--
-- The county-level income/acquisition figures loaded below ARE
-- real, current, primary-source data -- pulled directly from
-- IHCDA's own Inc-Acq-Limits-FS-SD-NH-4-21-2025.pdf (the same
-- document already used for the base First Step figures),
-- specifically the second/indented row under each "+"-marked
-- county. Effective April 21, 2025. Safe to trust.
--
-- The TRACT LIST (which specific tracts count as "targeted"
-- within those 17 counties) is NOT similarly current. IHCDA's
-- Targeted Areas page (in.gov/ihcda/lenders-and-realtors/
-- targeted-areas) links to CENSUS-TRACTS-FOR-TARGETED-AREAS_
-- 7.14.2020.pdf -- a document last updated July 14, 2020, five
-- years before the income limits it's supposed to support.
-- Concrete evidence it's stale:
--   - Hancock County is marked "+" (has a targeted tract) in
--     the current 2025 income limits, but has ZERO tracts
--     listed in the 2020 document at all. Not loaded here --
--     no real data exists to load.
--   - The 2020 document also lists tracts for Cass, Clay,
--     Dearborn, Jay, Noble, Porter, Randolph, Switzerland, and
--     Wells -- none of which are marked "+" in the current 2025
--     limits (Dearborn is now a whole-county "*" instead). Not
--     loaded here -- out of scope for the current 17-county set
--     and would misrepresent current program administration.
--
-- This is flagged as an open question in the email already sent
-- to homeownership@ihcda.in.gov. Until confirmed, matchingEngine.js
-- treats every income_threshold / purchase_price_cap evaluation
-- in these 17 counties as needsVerification rather than a
-- computed pass/fail -- see the corresponding JS changes.
--
-- Safe to re-run: every insert below is idempotent (on conflict
-- do nothing / existence checks).
-- ============================================================


-- ------------------------------------------------------------
-- 1. buyer_profiles: recover the census tract geocode.js
--    already computes but intakeForm.js currently discards.
-- ------------------------------------------------------------
alter table buyer_profiles
  add column if not exists purchase_census_tract text;


-- ------------------------------------------------------------
-- 2. Targeted-tract membership table (real, but explicitly
--    unverified-current, 2020-sourced data for 16 of the 17
--    counties -- Hancock intentionally excluded, see above).
-- ------------------------------------------------------------
create table if not exists targeted_census_tracts (
  id                  uuid primary key default gen_random_uuid(),
  state_code          char(2) not null references states(state_code),
  county_fips         text not null,
  tract_geoid         text not null,
  source_url          text,
  source_last_updated date,
  last_verified_date  date not null default current_date,
  created_at          timestamptz not null default now(),
  unique (state_code, tract_geoid)
);

create index if not exists idx_targeted_census_tracts_county
  on targeted_census_tracts(state_code, county_fips);

alter table targeted_census_tracts enable row level security;

-- Public read, matching every other geography-reference table
-- (geo_lookup_tables/values, occupation_taxonomy) -- this is
-- reference data, not buyer PII. Deliberately NOT repeating the
-- geo_lookup_tables gotcha (missing public-read policy caused
-- silent empty results for every lookup until patched).
drop policy if exists "public read targeted_census_tracts" on targeted_census_tracts;
create policy "public read targeted_census_tracts"
  on targeted_census_tracts for select
  using (true);


-- Source metadata used for every row inserted below.
do $$
declare
  v_source_url text := 'https://www.in.gov/ihcda/files/CENSUS-TRACTS-FOR-TARGETED-AREAS_7.14.2020.pdf';
  v_source_date date := '2020-07-14';
  v_tracts text[];
  v_county_fips text;
  v_t text;
begin
  -- Allen (18003)
  v_county_fips := '18003';
  v_tracts := array['18003000500','18003000600','18003000701','18003001200','18003001300',
    '18003001600','18003001700','18003002000','18003002100','18003002300',
    '18003002600','18003002800','18003002900','18003003000','18003003100',
    '18003003500','18003003600','18003004000','18003004300','18003004400',
    '18003010604','18003011201','18003011302','18003011303','18003980001'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Clark (18019)
  v_county_fips := '18019';
  v_tracts := array['18019050200','18019050306','18019050504'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Delaware (18035)
  v_county_fips := '18035';
  v_tracts := array['18035000300','18035000400','18035000500','18035000600','18035000902',
    '18035000903','18035001000','18035001200','18035001600','18035001700',
    '18035002000','18035002800'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Elkhart (18039)
  v_county_fips := '18039';
  v_tracts := array['18039001501','18039001901','18039002102','18039002300','18039002600','18039002700'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Floyd (18043)
  v_county_fips := '18043';
  v_tracts := array['18043070200','18043070400','18043070500','18043070700','18043070801','18043070902'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Grant (18053)
  v_county_fips := '18053';
  v_tracts := array['18053000100','18053000200','18053000400','18053000700','18053000800','18053000900'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Henry (18065)
  v_county_fips := '18065';
  v_tracts := array['18065976300','18065976500'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Howard (18067)
  v_county_fips := '18067';
  v_tracts := array['18067000200','18067000400','18067000900','18067001200'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Lake (18089)
  v_county_fips := '18089';
  v_tracts := array['18089010201','18089010203','18089010205','18089010302','18089010304',
    '18089010400','18089010500','18089010600','18089010900','18089011000',
    '18089011100','18089011200','18089011300','18089011400','18089011500',
    '18089011600','18089011700','18089011800','18089011900','18089012000',
    '18089012100','18089012200','18089012300','18089012400','18089012600',
    '18089012700','18089012800','18089020300','18089020400','18089020500',
    '18089020600','18089020700','18089020800','18089021400','18089021800',
    '18089030100','18089030200','18089030300','18089030400','18089030500',
    '18089030600','18089030800','18089031000','18089041100','18089041200',
    '18089041500','18089041700'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Madison (18095)
  v_county_fips := '18095';
  v_tracts := array['18095000300','18095000400','18095000500','18095000800','18095000900',
    '18095001000','18095011900','18095012000'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Marion (18097) -- large tract list, downtown/inner Indianapolis
  v_county_fips := '18097';
  v_tracts := array['18097310305','18097310306','18097320108','18097320902','18097320903',
    '18097322500','18097322600','18097330106','18097330600','18097330700',
    '18097330803','18097330804','18097330805','18097330806','18097330900',
    '18097340108','18097340201','18097340202','18097340300','18097340400',
    '18097340500','18097340600','18097340700','18097340902','18097341100',
    '18097341200','18097341600','18097341700','18097341903','18097342200',
    '18097342300','18097342400','18097342500','18097342600','18097350100',
    '18097350300','18097350400','18097350500','18097350600','18097350700',
    '18097350800','18097351000','18097351200','18097351500','18097351700',
    '18097351900','18097352100','18097352300','18097352400','18097352600',
    '18097352700','18097353300','18097353500','18097353600','18097354500',
    '18097354700','18097354800','18097354900','18097355000','18097355100',
    '18097355300','18097355700','18097355900','18097356400','18097356900',
    '18097357200','18097355400','18097355500','18097355600','18097357000',
    '18097357100','18097357300','18097357400','18097357600','18097357800',
    '18097358000','18097358100','18097360101','18097360102','18097360201',
    '18097360302','18097360401','18097360402','18097360404','18097360800',
    '18097360900','18097370202','18097380200','18097380300','18097380402',
    '18097380502','18097380600','18097380700','18097381001','18097381203',
    '18097381204','18097390500','18097390700'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Marshall (18099)
  v_county_fips := '18099';
  v_tracts := array['18099020500'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Monroe (18105)
  v_county_fips := '18105';
  v_tracts := array['18105000100','18105000201','18105000202','18105000301','18105000601',
    '18105000602','18105000901','18105000903','18105001600'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- St. Joseph (18141)
  v_county_fips := '18141';
  v_tracts := array['18141000200','18141000400','18141000500','18141000600','18141001000',
    '18141001500','18141001700','18141001900','18141002000','18141002100',
    '18141002200','18141002300','18141002400','18141002700','18141002800',
    '18141002900','18141003000','18141003400','18141003500','18141011201',
    '18141011202','18141011301','18141011501'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Tippecanoe (18157)
  v_county_fips := '18157';
  v_tracts := array['18157000100','18157000200','18157000400','18157005300','18157005400',
    '18157005500','18157010204','18157010500'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Vanderburgh (18163)
  v_county_fips := '18163';
  v_tracts := array['18163000300','18163000900','18163001000','18163001100','18163001200',
    '18163001300','18163001400','18163001500','18163001700','18163001900',
    '18163002000','18163002100','18163002300','18163002500','18163002600',
    '18163003200','18163003300','18163003702'];
  foreach v_t in array v_tracts loop
    insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
    values ('IN', v_county_fips, v_t, v_source_url, v_source_date)
    on conflict (state_code, tract_geoid) do nothing;
  end loop;

  -- Hancock (18059): deliberately NOT loaded. Marked "+" in the
  -- current 2025 income limits but has zero tracts in the 2020
  -- source document. No real data exists to load; the engine
  -- handles this county explicitly (see matchingEngine.js) as a
  -- "known targeted county, no tract inventory on file" case,
  -- distinct from ordinary non-targeted counties.

  raise notice 'Targeted census tract data loaded for 16 of 17 counties (Hancock intentionally excluded -- no source data).';
end $$;


-- ------------------------------------------------------------
-- 3. Real, current (2025-04-21) targeted-tier income and
--    acquisition limits for all 17 counties. This data is NOT
--    the unverified part of this migration -- same primary
--    source as the already-loaded base figures.
-- ------------------------------------------------------------
do $$
declare
  v_income_table_id uuid;
  v_acq_table_id    uuid;
  v_source_url text := 'https://secure.in.gov/ihcda/files/Inc-Acq-Limits-FS-SD-NH-4-21-2025.pdf';
  v_effective_date date := '2025-04-21';

  -- county_fips, 1-2 person income, 3+ person income, acquisition cap
  v_rows text[][] := array[
    ['18003','107640','125580','594770'], -- Allen
    ['18019','115920','135240','594770'], -- Clark
    ['18035','107640','125580','594770'], -- Delaware
    ['18039','107640','125580','594770'], -- Elkhart
    ['18043','115920','135240','594770'], -- Floyd
    ['18053','107640','125580','594770'], -- Grant
    ['18059','132840','154980','594770'], -- Hancock (income data IS real/loaded; only the tract list is missing)
    ['18065','107640','125580','594770'], -- Henry
    ['18067','107640','125580','594770'], -- Howard
    ['18089','114720','133840','594770'], -- Lake
    ['18095','107640','125580','594770'], -- Madison
    ['18097','132840','154980','594770'], -- Marion
    ['18099','110400','128800','594770'], -- Marshall
    ['18105','130080','151760','594770'], -- Monroe
    ['18141','107640','125580','594770'], -- St. Joseph
    ['18157','108720','126840','594770'], -- Tippecanoe
    ['18163','108720','126840','594770']  -- Vanderburgh
  ];
  v_row text[];
begin
  -- Create (or find) the two new geo_lookup_tables entries.
  insert into geo_lookup_tables (table_name, description, value_type)
  values (
    'ihcda_first_step_income_limits_targeted',
    'IHCDA First Step -- higher income limit that applies when a purchase is in a qualifying targeted census tract (17 counties). Real data from the same 2025-04-21 primary source as the base table; pairs with targeted_census_tracts for tract-level determination.',
    'income_limit'
  )
  on conflict (table_name) do nothing;

  insert into geo_lookup_tables (table_name, description, value_type)
  values (
    'ihcda_first_step_acquisition_limit_targeted',
    'IHCDA First Step -- higher acquisition/purchase-price limit that applies when a purchase is in a qualifying targeted census tract (17 counties). Real data from the same 2025-04-21 primary source as the base table.',
    'purchase_price_cap'
  )
  on conflict (table_name) do nothing;

  select id into v_income_table_id from geo_lookup_tables where table_name = 'ihcda_first_step_income_limits_targeted';
  select id into v_acq_table_id from geo_lookup_tables where table_name = 'ihcda_first_step_acquisition_limit_targeted';

  foreach v_row slice 1 in array v_rows loop
    -- income: household_size=2 bucket ("1-2 person"), same bracket convention as the base table
    insert into geo_lookup_values (lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url)
    select v_income_table_id, 'IN', v_row[1], 2, v_row[2]::numeric, v_effective_date, v_source_url
    where not exists (
      select 1 from geo_lookup_values
      where lookup_table_id = v_income_table_id and county_fips = v_row[1] and household_size = 2
    );

    -- income: household_size=3 bucket ("3+ person")
    insert into geo_lookup_values (lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url)
    select v_income_table_id, 'IN', v_row[1], 3, v_row[3]::numeric, v_effective_date, v_source_url
    where not exists (
      select 1 from geo_lookup_values
      where lookup_table_id = v_income_table_id and county_fips = v_row[1] and household_size = 3
    );

    -- acquisition cap: doesn't vary by household size
    insert into geo_lookup_values (lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url)
    select v_acq_table_id, 'IN', v_row[1], null, v_row[4]::numeric, v_effective_date, v_source_url
    where not exists (
      select 1 from geo_lookup_values
      where lookup_table_id = v_acq_table_id and county_fips = v_row[1] and household_size is null
    );
  end loop;

  raise notice 'Targeted income/acquisition limits loaded for all 17 counties (income_table=%, acq_table=%)', v_income_table_id, v_acq_table_id;
end $$;


-- ------------------------------------------------------------
-- 4. Point the existing IHCDA rules at the new targeted tables.
--    Defensive: raises a notice (not an exception) if the base
--    rule_config doesn't have the expected 'lookup_table' key,
--    since financial_underwriting's exact shape wasn't confirmed
--    ahead of writing this -- check manually if you see that
--    notice rather than assuming this silently did nothing.
-- ------------------------------------------------------------
do $$
declare
  v_program_id uuid;
  v_income_rule_id uuid;
  v_price_rule_id uuid;
  v_income_config jsonb;
  v_price_config jsonb;
begin
  select id into v_program_id from programs where name ilike '%IHCDA%First Step%' limit 1;
  if v_program_id is null then
    raise exception 'Could not find IHCDA First Step program -- check programs.name';
  end if;

  select id, rule_config into v_income_rule_id, v_income_config
  from program_eligibility_rules
  where program_id = v_program_id and rule_type = 'income_threshold'
  limit 1;

  if v_income_rule_id is null then
    raise exception 'Could not find income_threshold rule for IHCDA First Step';
  end if;

  if v_income_config ? 'lookup_table' then
    update program_eligibility_rules
    set rule_config = rule_config || jsonb_build_object(
      'targeted_lookup_table', 'ihcda_first_step_income_limits_targeted',
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', 'https://www.in.gov/ihcda/files/CENSUS-TRACTS-FOR-TARGETED-AREAS_7.14.2020.pdf'
    )
    where id = v_income_rule_id;
    raise notice 'income_threshold rule % updated with targeted_lookup_table', v_income_rule_id;
  else
    raise notice 'income_threshold rule % rule_config has no "lookup_table" key -- expected shape not found, did NOT modify. Check rule_config manually: %', v_income_rule_id, v_income_config;
  end if;

  select id, rule_config into v_price_rule_id, v_price_config
  from program_eligibility_rules
  where program_id = v_program_id and rule_type = 'financial_underwriting'
    and rule_config ->> 'field' = 'purchase_price_cap'
  limit 1;

  if v_price_rule_id is null then
    raise notice 'Could not find financial_underwriting/purchase_price_cap rule -- skipping price-cap targeting update. Check program_eligibility_rules manually.';
  elsif v_price_config ? 'lookup_table' then
    update program_eligibility_rules
    set rule_config = rule_config || jsonb_build_object(
      'targeted_lookup_table', 'ihcda_first_step_acquisition_limit_targeted',
      'targeted_tract_data_status', 'needsVerification',
      'targeted_tract_source_url', 'https://www.in.gov/ihcda/files/CENSUS-TRACTS-FOR-TARGETED-AREAS_7.14.2020.pdf'
    )
    where id = v_price_rule_id;
    raise notice 'financial_underwriting/purchase_price_cap rule % updated with targeted_lookup_table', v_price_rule_id;
  else
    raise notice 'purchase_price_cap rule % rule_config has no "lookup_table" key -- expected shape not found, did NOT modify. Check rule_config manually: %', v_price_rule_id, v_price_config;
  end if;
end $$;
