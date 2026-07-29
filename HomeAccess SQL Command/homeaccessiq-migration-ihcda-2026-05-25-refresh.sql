-- ============================================================
-- IHCDA First Step / Step Down / Next Home -- 2026-05-25 refresh
-- ============================================================
--
-- This RESOLVES the open discrepancy flagged in the original
-- project handoff: "a secondhand source claiming a 'May 25, 2026'
-- edition exists". Confirmed real and current -- today is
-- 2026-07-29, so this document is the currently-effective one,
-- superseding the 2025-04-21 figures this entire project (both
-- the base data and everything built this session) was built
-- against.
--
-- GOOD NEWS: the county classifications did NOT change. Same 30
-- whole-county-targeted ("*") counties, same 17 tract-targeted
-- ("+") counties, in the exact same configuration as the
-- 2025-04-21 document. This is a pure dollar-figure refresh
-- (reads like a standard periodic AMI update) -- no schema or
-- engine changes needed, unlike the tract-targeting work earlier
-- this session.
--
-- APPROACH: updates existing rows IN PLACE rather than inserting
-- parallel historical rows. fetchGeoLookupValue() doesn't filter
-- on effective_date today, so leaving old rows alongside new ones
-- would create ambiguous duplicates. If point-in-time lookups are
-- ever added later, this in-place approach would need revisiting.
--
-- FLAG FOR MANUAL CHECK BEFORE TRUSTING FULLY: Daviess and Decatur
-- show $33,420 for the 3+ person bracket in the source document --
-- every other one of the 30 whole-county-targeted counties at this
-- same tier shows exactly $133,420. Loaded as $133,420 here to
-- match the overwhelming internal pattern (there's no plausible
-- reason these two alone would sit $100k below every peer at the
-- same tier), but this is an assumption about a likely missing
-- leading "1" in the source PDF, not a confirmed reading -- worth
-- a direct look at that PDF page to confirm before fully trusting.
--
-- source_url below is INFERRED from the prior document's naming
-- pattern (Inc-Acq-Limits-FS-SD-NH-4-21-2025.pdf ->
-- Inc-Acq-Limits-FS-SD-NH-5-26-26.pdf) since this file was
-- provided directly rather than fetched from a URL in this
-- session. Confirm/replace if you have the actual link.
-- ============================================================

do $$
declare
  v_program_id      uuid;
  v_income_config   jsonb;
  v_price_config    jsonb;
  v_income_table_id uuid;
  v_acq_table_id    uuid;
  v_source_url text := 'https://secure.in.gov/ihcda/files/Inc-Acq-Limits-FS-SD-NH-5-26-26.pdf';
  v_effective_date date := '2026-05-25';
  rec record;
  v_income_updated int := 0;
  v_acq_updated int := 0;
begin
  select id into v_program_id from programs where name ilike '%IHCDA%First Step%' limit 1;
  if v_program_id is null then
    raise exception 'Could not find IHCDA First Step program -- check programs.name';
  end if;

  select rule_config into v_income_config
  from program_eligibility_rules
  where program_id = v_program_id and rule_type = 'income_threshold'
  limit 1;

  select rule_config into v_price_config
  from program_eligibility_rules
  where program_id = v_program_id and rule_type = 'financial_underwriting'
    and rule_config ->> 'field' = 'purchase_price_cap'
  limit 1;

  select id into v_income_table_id from geo_lookup_tables where table_name = v_income_config ->> 'lookup_table';
  select id into v_acq_table_id from geo_lookup_tables where table_name = v_price_config ->> 'lookup_table';

  if v_income_table_id is null then
    raise exception 'Could not resolve base income lookup_table from rule_config: %', v_income_config;
  end if;
  if v_acq_table_id is null then
    raise exception 'Could not resolve base acquisition lookup_table from rule_config: %', v_price_config;
  end if;

  -- All 92 Indiana counties: fips, 1-2 person income, 3+ person
  -- income, acquisition limit. For "*" whole-county-targeted
  -- counties this IS the single elevated figure (no separate
  -- tier -- matches how the original base table was designed).
  -- For "+" tract counties this is the BASE (non-targeted) figure
  -- -- their elevated tier is the separate targeted table updated
  -- further below.
  for rec in (
    select * from (values
      ('18001',  95300, 109595, 566355), -- Adams
      ('18003',  95300, 109595, 566355), -- Allen+ (base)
      ('18005',  97100, 111665, 566355), -- Bartholomew
      ('18007',  99600, 114540, 566355), -- Benton
      ('18009',  95300, 109595, 566355), -- Blackford
      ('18011', 110300, 126845, 566355), -- Boone
      ('18013', 132360, 154420, 692211), -- Brown*
      ('18015',  95300, 109595, 566355), -- Carroll
      ('18017',  95300, 109595, 566355), -- Cass
      ('18019',  99000, 113850, 566355), -- Clark+ (base)
      ('18021',  95300, 109595, 566355), -- Clay
      ('18023', 114360, 133420, 692211), -- Clinton*
      ('18025', 114360, 133420, 692211), -- Crawford*
      ('18027', 114360, 133420, 692211), -- Daviess* -- see flag above re: 3+ figure
      ('18029', 131880, 153860, 692211), -- Dearborn*
      ('18031', 114360, 133420, 692211), -- Decatur* -- see flag above re: 3+ figure
      ('18033',  95300, 109595, 566355), -- DeKalb
      ('18035',  95300, 109595, 566355), -- Delaware+ (base)
      ('18037',  96100, 110515, 566355), -- Dubois
      ('18039',  95300, 109595, 566355), -- Elkhart+ (base)
      ('18041', 114360, 133420, 692211), -- Fayette*
      ('18043',  99000, 113850, 566355), -- Floyd+ (base)
      ('18045',  95300, 109595, 566355), -- Fountain
      ('18047', 116880, 136360, 692211), -- Franklin*
      ('18049', 114360, 133420, 692211), -- Fulton*
      ('18051',  95300, 109595, 566355), -- Gibson
      ('18053',  95300, 109595, 566355), -- Grant+ (base)
      ('18055', 114360, 133420, 692211), -- Greene*
      ('18057', 110300, 126845, 566355), -- Hamilton
      ('18059', 110300, 126845, 566355), -- Hancock+ (base)
      ('18061',  99000, 113850, 566355), -- Harrison
      ('18063', 110300, 126845, 566355), -- Hendricks
      ('18065',  95300, 109595, 566355), -- Henry+ (base)
      ('18067',  95300, 109595, 566355), -- Howard+ (base)
      ('18069',  95300, 109595, 566355), -- Huntington
      ('18071', 114360, 133420, 692211), -- Jackson*
      ('18073', 117120, 136640, 692211), -- Jasper*
      ('18075',  95300, 109595, 566355), -- Jay
      ('18077', 114360, 133420, 692211), -- Jefferson*
      ('18079',  95300, 109595, 566355), -- Jennings
      ('18081', 110300, 126845, 566355), -- Johnson
      ('18083', 114360, 133420, 692211), -- Knox*
      ('18085',  95300, 109595, 566355), -- Kosciusko
      ('18087',  97400, 112010, 566355), -- LaGrange
      ('18089', 100900, 116035, 566355), -- Lake+ (base)
      ('18091',  95300, 109595, 566355), -- LaPorte
      ('18093', 114360, 133420, 692211), -- Lawrence*
      ('18095',  95300, 109595, 566355), -- Madison+ (base)
      ('18097', 110300, 126845, 566355), -- Marion+ (base)
      ('18099',  95300, 109595, 566355), -- Marshall+ (base)
      ('18101',  95300, 109595, 566355), -- Martin
      ('18103', 114360, 133420, 692211), -- Miami*
      ('18105', 109900, 126385, 566355), -- Monroe+ (base)
      ('18107',  96600, 110090, 566355), -- Montgomery
      ('18109', 110300, 126845, 566355), -- Morgan
      ('18111', 110900, 116035, 566355), -- Newton
      ('18113',  95300, 109595, 566355), -- Noble
      ('18115', 131880, 153860, 692211), -- Ohio*
      ('18117', 114360, 133420, 692211), -- Orange*
      ('18119', 114360, 133420, 692211), -- Owen*
      ('18121', 114360, 133420, 692211), -- Parke*
      ('18123', 114360, 133420, 692211), -- Perry*
      ('18125', 114360, 133420, 692211), -- Pike*
      ('18127', 100900, 116035, 566355), -- Porter
      ('18129',  95300, 109595, 566355), -- Posey
      ('18131',  95300, 109595, 566355), -- Pulaski
      ('18133',  95300, 109595, 566355), -- Putnam
      ('18135',  95300, 109595, 566355), -- Randolph
      ('18137',  95300, 109595, 566355), -- Ripley
      ('18139', 114360, 133420, 692211), -- Rush*
      ('18141',  99400, 114310, 566355), -- St. Joseph+ (base)
      ('18143', 114360, 133420, 692211), -- Scott*
      ('18145', 114360, 133420, 692211), -- Shelby*
      ('18147', 132360, 154420, 692211), -- Spencer*
      ('18149',  95300, 109595, 566355), -- Starke
      ('18151',  95700, 110055, 566355), -- Steuben
      ('18153',  95300, 109595, 566355), -- Sullivan
      ('18155',  95300, 109595, 566355), -- Switzerland
      ('18157',  99600, 114540, 566355), -- Tippecanoe+ (base)
      ('18159',  95300, 109595, 566355), -- Tipton
      ('18161',  98000, 112700, 566355), -- Union
      ('18163',  95300, 109595, 566355), -- Vanderburgh+ (base)
      ('18165', 114360, 133420, 692211), -- Vermillion*
      ('18167', 114360, 133420, 692211), -- Vigo*
      ('18169',  95300, 109595, 566355), -- Wabash
      ('18171', 106200, 122130, 566355), -- Warren
      ('18173',  95300, 109595, 566355), -- Warrick
      ('18175', 114360, 133420, 692211), -- Washington*
      ('18177', 114360, 133420, 692211), -- Wayne*
      ('18179',  95300, 109595, 566355), -- Wells
      ('18181',  95300, 109595, 566355), -- White
      ('18183',  95300, 109595, 566355)  -- Whitley
    ) as t(fips, inc_1_2, inc_3plus, acq)
  ) loop
    update geo_lookup_values
    set numeric_value = rec.inc_1_2, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_income_table_id and county_fips = rec.fips and household_size = 2;
    get diagnostics v_income_updated = row_count;

    update geo_lookup_values
    set numeric_value = rec.inc_3plus, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_income_table_id and county_fips = rec.fips and household_size = 3;

    update geo_lookup_values
    set numeric_value = rec.acq, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_acq_table_id and county_fips = rec.fips and household_size is null;
  end loop;

  raise notice 'Base income/acquisition tables refreshed to 2026-05-25 figures for all 92 counties (income_table=%, acq_table=%)', v_income_table_id, v_acq_table_id;
end $$;


-- ------------------------------------------------------------
-- Now refresh the two TARGETED tables added earlier this
-- session, for the 17 tract counties' elevated tier.
-- ------------------------------------------------------------
do $$
declare
  v_income_table_id uuid;
  v_acq_table_id    uuid;
  v_source_url text := 'https://secure.in.gov/ihcda/files/Inc-Acq-Limits-FS-SD-NH-5-26-26.pdf';
  v_effective_date date := '2026-05-25';
  rec record;
begin
  select id into v_income_table_id from geo_lookup_tables where table_name = 'ihcda_first_step_income_limits_targeted';
  select id into v_acq_table_id from geo_lookup_tables where table_name = 'ihcda_first_step_acquisition_limit_targeted';

  if v_income_table_id is null or v_acq_table_id is null then
    raise exception 'Could not find the targeted geo_lookup_tables rows -- did the earlier targeted-tract migration run?';
  end if;

  for rec in (
    select * from (values
      ('18003', 114360, 133420, 692211), -- Allen
      ('18019', 118800, 138600, 692211), -- Clark
      ('18035', 114360, 133420, 692211), -- Delaware
      ('18039', 114360, 133420, 692211), -- Elkhart
      ('18043', 118800, 138600, 692211), -- Floyd
      ('18053', 114360, 133420, 692211), -- Grant
      ('18059', 132360, 154420, 692211), -- Hancock (income real/loaded; tract list still missing)
      ('18065', 114360, 133420, 692211), -- Henry
      ('18067', 114360, 133420, 692211), -- Howard
      ('18089', 121080, 141260, 692211), -- Lake
      ('18095', 114360, 133420, 692211), -- Madison
      ('18097', 132360, 154420, 692211), -- Marion
      ('18099', 114360, 133420, 692211), -- Marshall
      ('18105', 131880, 153860, 692211), -- Monroe
      ('18141', 114360, 133420, 692211), -- St. Joseph
      ('18157', 119520, 139440, 692211), -- Tippecanoe
      ('18163', 114360, 133420, 692211)  -- Vanderburgh
    ) as t(fips, inc_1_2, inc_3plus, acq)
  ) loop
    update geo_lookup_values
    set numeric_value = rec.inc_1_2, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_income_table_id and county_fips = rec.fips and household_size = 2;

    update geo_lookup_values
    set numeric_value = rec.inc_3plus, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_income_table_id and county_fips = rec.fips and household_size = 3;

    update geo_lookup_values
    set numeric_value = rec.acq, effective_date = v_effective_date, source_url = v_source_url
    where lookup_table_id = v_acq_table_id and county_fips = rec.fips and household_size is null;
  end loop;

  raise notice 'Targeted-tier tables refreshed to 2026-05-25 figures for all 17 tract counties';
end $$;
