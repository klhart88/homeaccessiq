-- Migration: Populate FL Assist / FL HLP income & purchase-price limits
-- Source: Florida Housing Standard Bond Guide 6.25.26 (Lakeview), effective with
-- reservation 2026-05-06. All 67 FL counties. Supersedes the placeholder
-- 'fl_housing_standard_income_limits' / 'fl_housing_standard_purchase_price_limits'
-- registered (but never populated) by the prior income-caveat migration --
-- those are left in place but unused; do not delete in case anything still points at them.
--
-- IMPORTANT FINDING: FL Assist and FL HLP's NonTargeted 3+ Person income figures
-- are NOT identical in 9 counties (Baker, Collier, Gulf, Martin, Monroe, Okaloosa,
-- Polk, St. Lucie, Walton) -- confirmed by direct row comparison of both tables
-- in the source guide. This is why FL Assist and FL HLP each get their own
-- lookup tables rather than sharing one, unlike what was assumed at first.
--
-- Purchase price limits WERE verified identical between the two programs'
-- own tables in the source guide, so those two tables are shared.
--
-- STILL OPEN: HFA Preferred/Advantage PLUS Second Mortgage has no income/purchase
-- price limits in this Bond Guide at all (it's a TBA-only product -- see 'PLUS TBA'
-- on the eHousingPlus rate page, no 'PLUS BOND' product exists). Its
-- income_threshold/financial_underwriting rules are NOT touched by this migration
-- and still point at the old empty placeholder tables. Needs the separate TBA
-- program lender guide as its own source before it can be populated.
--
-- ARCHITECTURE NOTE: rule_config below adds a 'targeted_lookup_table' key alongside
-- the existing 'lookup_table' key. The matching engine (intake-controller.js) will
-- need a corresponding code change to actually consult targeted_lookup_table when
-- the property is in a Federally Designated Targeted Area -- this migration only
-- prepares the data and rule_config, it does not implement that branch in the app.
--
-- source_url intentionally NULL: no public URL confirmed for this guide yet;
-- sourced from Florida Housing Standard Bond Guide 6.25.26 (Lakeview) PDF provided
-- directly, not fetched from web. Confirm with FL Housing whether this guide is
-- posted publicly and backfill source_url if so.

-- 1. Register the six lookup tables
insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_assist_income_limits_nontargeted', 'Income limits (NonTargeted) for FL Assist Second Mortgage, by county and household-size bracket (2=1-2 person, 3=3+ person). Standard Bond/TBA programs.', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_assist_income_limits_nontargeted');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_assist_income_limits_targeted', 'Income limits (Targeted Areas) for FL Assist Second Mortgage. FL Assist does not split Targeted by household size -- same value stored at household_size 2 and 3.', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_assist_income_limits_targeted');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_hlp_income_limits_nontargeted', 'Income limits (NonTargeted) for FL Homeownership Loan Program (HLP) Second Mortgage, by county and household-size bracket. NOTE: differs from FL Assist''s NonTargeted 3+ figures in 9 counties (Baker, Collier, Gulf, Martin, Monroe, Okaloosa, Polk, St. Lucie, Walton) -- confirmed via direct comparison, not an error, kept as a separate table for this reason.', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_hlp_income_limits_nontargeted');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_hlp_income_limits_targeted', 'Income limits (Targeted Areas) for FL HLP Second Mortgage. Unlike FL Assist, HLP''s Targeted column splits by household size (1-2 vs 3+).', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_hlp_income_limits_targeted');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_housing_purchase_price_limits_nontargeted', 'Purchase price limits (NonTargeted), by county. Verified identical between FL Assist''s and FL HLP''s own tables in the source guide -- shared across both programs.', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_housing_purchase_price_limits_nontargeted');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_housing_purchase_price_limits_targeted', 'Purchase price limits (Targeted Areas), by county. Verified identical between FL Assist''s and FL HLP''s own tables in the source guide -- shared across both programs.', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_housing_purchase_price_limits_targeted');

-- 2. Populate income limit rows (household_size 2 = 1-2 person, 3 = 3+ person)
-- Populate fl_assist_income_limits_nontargeted
-- FL Assist NonTargeted -- 1-2 person / 3+ person.
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', 2, 104000),
    ('FL', '12001', 3, 119600),
    ('FL', '12003', 2, 110061),
    ('FL', '12003', 3, 120720),
    ('FL', '12005', 2, 101554),
    ('FL', '12005', 3, 116788),
    ('FL', '12007', 2, 98700),
    ('FL', '12007', 3, 113540),
    ('FL', '12009', 2, 101414),
    ('FL', '12009', 3, 116627),
    ('FL', '12011', 2, 126800),
    ('FL', '12011', 3, 145820),
    ('FL', '12013', 2, 98700),
    ('FL', '12013', 3, 113505),
    ('FL', '12015', 2, 102034),
    ('FL', '12015', 3, 117340),
    ('FL', '12017', 2, 98700),
    ('FL', '12017', 3, 113505),
    ('FL', '12019', 2, 108700),
    ('FL', '12019', 3, 125005),
    ('FL', '12021', 2, 145200),
    ('FL', '12021', 3, 145200),
    ('FL', '12023', 2, 99600),
    ('FL', '12023', 3, 116200),
    ('FL', '12027', 2, 98700),
    ('FL', '12027', 3, 113505),
    ('FL', '12029', 2, 98700),
    ('FL', '12029', 3, 113505),
    ('FL', '12031', 2, 108700),
    ('FL', '12031', 3, 125005),
    ('FL', '12033', 2, 102694),
    ('FL', '12033', 3, 118099),
    ('FL', '12035', 2, 104300),
    ('FL', '12035', 3, 119945),
    ('FL', '12037', 2, 98760),
    ('FL', '12037', 3, 115220),
    ('FL', '12039', 2, 101434),
    ('FL', '12039', 3, 116650),
    ('FL', '12041', 2, 104000),
    ('FL', '12041', 3, 119600),
    ('FL', '12043', 2, 98700),
    ('FL', '12043', 3, 113505),
    ('FL', '12045', 2, 103320),
    ('FL', '12045', 3, 118440),
    ('FL', '12047', 2, 98700),
    ('FL', '12047', 3, 113505),
    ('FL', '12049', 2, 98700),
    ('FL', '12049', 3, 113505),
    ('FL', '12051', 2, 98700),
    ('FL', '12051', 3, 113505),
    ('FL', '12053', 2, 114700),
    ('FL', '12053', 3, 131905),
    ('FL', '12055', 2, 98700),
    ('FL', '12055', 3, 113505),
    ('FL', '12057', 2, 114700),
    ('FL', '12057', 3, 131905),
    ('FL', '12059', 2, 98700),
    ('FL', '12059', 3, 113505),
    ('FL', '12061', 2, 102300),
    ('FL', '12061', 3, 117645),
    ('FL', '12063', 2, 98700),
    ('FL', '12063', 3, 113505),
    ('FL', '12065', 2, 101434),
    ('FL', '12065', 3, 116650),
    ('FL', '12067', 2, 98700),
    ('FL', '12067', 3, 113505),
    ('FL', '12069', 2, 114900),
    ('FL', '12069', 3, 132135),
    ('FL', '12071', 2, 112400),
    ('FL', '12071', 3, 129260),
    ('FL', '12073', 2, 101434),
    ('FL', '12073', 3, 116650),
    ('FL', '12075', 2, 98700),
    ('FL', '12075', 3, 113505),
    ('FL', '12077', 2, 98700),
    ('FL', '12077', 3, 113505),
    ('FL', '12079', 2, 98700),
    ('FL', '12079', 3, 113505),
    ('FL', '12081', 2, 114100),
    ('FL', '12081', 3, 131215),
    ('FL', '12083', 2, 100800),
    ('FL', '12083', 3, 117600),
    ('FL', '12085', 2, 114856),
    ('FL', '12085', 3, 122880),
    ('FL', '12086', 2, 136200),
    ('FL', '12086', 3, 156630),
    ('FL', '12087', 2, 171960),
    ('FL', '12087', 3, 171960),
    ('FL', '12089', 2, 108700),
    ('FL', '12089', 3, 125005),
    ('FL', '12091', 2, 113996),
    ('FL', '12091', 3, 128040),
    ('FL', '12093', 2, 98700),
    ('FL', '12093', 3, 113505),
    ('FL', '12095', 2, 114900),
    ('FL', '12095', 3, 132135),
    ('FL', '12097', 2, 114900),
    ('FL', '12097', 3, 132135),
    ('FL', '12099', 2, 128500),
    ('FL', '12099', 3, 147775),
    ('FL', '12101', 2, 114700),
    ('FL', '12101', 3, 131905),
    ('FL', '12103', 2, 114700),
    ('FL', '12103', 3, 131905),
    ('FL', '12105', 2, 103874),
    ('FL', '12105', 3, 118440),
    ('FL', '12107', 2, 98700),
    ('FL', '12107', 3, 113505),
    ('FL', '12109', 2, 108700),
    ('FL', '12109', 3, 125005),
    ('FL', '12111', 2, 114856),
    ('FL', '12111', 3, 122880),
    ('FL', '12113', 2, 102694),
    ('FL', '12113', 3, 118099),
    ('FL', '12115', 2, 114100),
    ('FL', '12115', 3, 131215),
    ('FL', '12117', 2, 114900),
    ('FL', '12117', 3, 132135),
    ('FL', '12119', 2, 104100),
    ('FL', '12119', 3, 119715),
    ('FL', '12121', 2, 98700),
    ('FL', '12121', 3, 113505),
    ('FL', '12123', 2, 98700),
    ('FL', '12123', 3, 113505),
    ('FL', '12125', 2, 98700),
    ('FL', '12125', 3, 113505),
    ('FL', '12127', 2, 101514),
    ('FL', '12127', 3, 116742),
    ('FL', '12129', 2, 101254),
    ('FL', '12129', 3, 116443),
    ('FL', '12131', 2, 115816),
    ('FL', '12131', 3, 118440),
    ('FL', '12133', 2, 98700),
    ('FL', '12133', 3, 113505)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_assist_income_limits_nontargeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips and glv.household_size = v.household_size
);

-- Populate fl_assist_income_limits_targeted
-- FL Assist Targeted -- single figure per county, stored at both brackets (no size split in source).
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', 2, 124800),
    ('FL', '12001', 3, 124800),
    ('FL', '12003', 2, 120720),
    ('FL', '12003', 3, 120720),
    ('FL', '12005', 2, 118680),
    ('FL', '12005', 3, 118680),
    ('FL', '12007', 2, 118440),
    ('FL', '12007', 3, 118440),
    ('FL', '12009', 2, 119520),
    ('FL', '12009', 3, 119520),
    ('FL', '12011', 2, 152160),
    ('FL', '12011', 3, 152160),
    ('FL', '12013', 2, 118440),
    ('FL', '12013', 3, 118440),
    ('FL', '12015', 2, 118440),
    ('FL', '12015', 3, 118440),
    ('FL', '12017', 2, 118440),
    ('FL', '12017', 3, 118440),
    ('FL', '12019', 2, 130440),
    ('FL', '12019', 3, 130440),
    ('FL', '12021', 2, 145200),
    ('FL', '12021', 3, 145200),
    ('FL', '12023', 2, 118440),
    ('FL', '12023', 3, 118440),
    ('FL', '12027', 2, 118440),
    ('FL', '12027', 3, 118440),
    ('FL', '12029', 2, 118440),
    ('FL', '12029', 3, 118440),
    ('FL', '12031', 2, 130440),
    ('FL', '12031', 3, 130440),
    ('FL', '12033', 2, 118440),
    ('FL', '12033', 3, 118440),
    ('FL', '12035', 2, 125160),
    ('FL', '12035', 3, 125160),
    ('FL', '12037', 2, 118440),
    ('FL', '12037', 3, 118440),
    ('FL', '12039', 2, 119400),
    ('FL', '12039', 3, 119400),
    ('FL', '12041', 2, 124800),
    ('FL', '12041', 3, 124800),
    ('FL', '12043', 2, 118440),
    ('FL', '12043', 3, 118440),
    ('FL', '12045', 2, 118440),
    ('FL', '12045', 3, 118440),
    ('FL', '12047', 2, 118440),
    ('FL', '12047', 3, 118440),
    ('FL', '12049', 2, 118440),
    ('FL', '12049', 3, 118440),
    ('FL', '12051', 2, 118440),
    ('FL', '12051', 3, 118440),
    ('FL', '12053', 2, 137640),
    ('FL', '12053', 3, 137640),
    ('FL', '12055', 2, 118440),
    ('FL', '12055', 3, 118440),
    ('FL', '12057', 2, 137640),
    ('FL', '12057', 3, 137640),
    ('FL', '12059', 2, 118440),
    ('FL', '12059', 3, 118440),
    ('FL', '12061', 2, 122760),
    ('FL', '12061', 3, 122760),
    ('FL', '12063', 2, 118440),
    ('FL', '12063', 3, 118440),
    ('FL', '12065', 2, 119400),
    ('FL', '12065', 3, 119400),
    ('FL', '12067', 2, 118440),
    ('FL', '12067', 3, 118440),
    ('FL', '12069', 2, 137880),
    ('FL', '12069', 3, 137880),
    ('FL', '12071', 2, 134880),
    ('FL', '12071', 3, 134880),
    ('FL', '12073', 2, 119400),
    ('FL', '12073', 3, 119400),
    ('FL', '12075', 2, 118440),
    ('FL', '12075', 3, 118440),
    ('FL', '12077', 2, 118440),
    ('FL', '12077', 3, 118440),
    ('FL', '12079', 2, 118440),
    ('FL', '12079', 3, 118440),
    ('FL', '12081', 2, 136920),
    ('FL', '12081', 3, 136920),
    ('FL', '12083', 2, 118440),
    ('FL', '12083', 3, 118440),
    ('FL', '12085', 2, 122880),
    ('FL', '12085', 3, 122880),
    ('FL', '12086', 2, 163440),
    ('FL', '12086', 3, 163440),
    ('FL', '12087', 2, 171960),
    ('FL', '12087', 3, 171960),
    ('FL', '12089', 2, 130440),
    ('FL', '12089', 3, 130440),
    ('FL', '12091', 2, 128040),
    ('FL', '12091', 3, 128040),
    ('FL', '12093', 2, 118440),
    ('FL', '12093', 3, 118440),
    ('FL', '12095', 2, 137880),
    ('FL', '12095', 3, 137880),
    ('FL', '12097', 2, 137880),
    ('FL', '12097', 3, 137880),
    ('FL', '12099', 2, 154200),
    ('FL', '12099', 3, 154200),
    ('FL', '12101', 2, 137640),
    ('FL', '12101', 3, 137640),
    ('FL', '12103', 2, 137640),
    ('FL', '12103', 3, 137640),
    ('FL', '12105', 2, 118440),
    ('FL', '12105', 3, 118440),
    ('FL', '12107', 2, 118440),
    ('FL', '12107', 3, 118440),
    ('FL', '12109', 2, 130440),
    ('FL', '12109', 3, 130440),
    ('FL', '12111', 2, 122880),
    ('FL', '12111', 3, 122880),
    ('FL', '12113', 2, 118440),
    ('FL', '12113', 3, 118440),
    ('FL', '12115', 2, 136920),
    ('FL', '12115', 3, 136920),
    ('FL', '12117', 2, 137880),
    ('FL', '12117', 3, 137880),
    ('FL', '12119', 2, 124920),
    ('FL', '12119', 3, 124920),
    ('FL', '12121', 2, 118440),
    ('FL', '12121', 3, 118440),
    ('FL', '12123', 2, 118440),
    ('FL', '12123', 3, 118440),
    ('FL', '12125', 2, 118440),
    ('FL', '12125', 3, 118440),
    ('FL', '12127', 2, 118920),
    ('FL', '12127', 3, 118920),
    ('FL', '12129', 2, 120480),
    ('FL', '12129', 3, 120480),
    ('FL', '12131', 2, 118440),
    ('FL', '12131', 3, 118440),
    ('FL', '12133', 2, 118440),
    ('FL', '12133', 3, 118440)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_assist_income_limits_targeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips and glv.household_size = v.household_size
);

-- Populate fl_hlp_income_limits_nontargeted
-- FL HLP NonTargeted -- 1-2 person / 3+ person. Diverges from FL Assist in 9 counties, see migration header.
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', 2, 104000),
    ('FL', '12001', 3, 119600),
    ('FL', '12003', 2, 110061),
    ('FL', '12003', 3, 126570),
    ('FL', '12005', 2, 101554),
    ('FL', '12005', 3, 116788),
    ('FL', '12007', 2, 98700),
    ('FL', '12007', 3, 113540),
    ('FL', '12009', 2, 101414),
    ('FL', '12009', 3, 116627),
    ('FL', '12011', 2, 126800),
    ('FL', '12011', 3, 145820),
    ('FL', '12013', 2, 98700),
    ('FL', '12013', 3, 113505),
    ('FL', '12015', 2, 102034),
    ('FL', '12015', 3, 117340),
    ('FL', '12017', 2, 98700),
    ('FL', '12017', 3, 113505),
    ('FL', '12019', 2, 108700),
    ('FL', '12019', 3, 125005),
    ('FL', '12021', 2, 145200),
    ('FL', '12021', 3, 169310),
    ('FL', '12023', 2, 99600),
    ('FL', '12023', 3, 116200),
    ('FL', '12027', 2, 98700),
    ('FL', '12027', 3, 113505),
    ('FL', '12029', 2, 98700),
    ('FL', '12029', 3, 113505),
    ('FL', '12031', 2, 108700),
    ('FL', '12031', 3, 125005),
    ('FL', '12033', 2, 102694),
    ('FL', '12033', 3, 118099),
    ('FL', '12035', 2, 104300),
    ('FL', '12035', 3, 119945),
    ('FL', '12037', 2, 98760),
    ('FL', '12037', 3, 115220),
    ('FL', '12039', 2, 101434),
    ('FL', '12039', 3, 116650),
    ('FL', '12041', 2, 104000),
    ('FL', '12041', 3, 119600),
    ('FL', '12043', 2, 98700),
    ('FL', '12043', 3, 113505),
    ('FL', '12045', 2, 103320),
    ('FL', '12045', 3, 119732),
    ('FL', '12047', 2, 98700),
    ('FL', '12047', 3, 113505),
    ('FL', '12049', 2, 98700),
    ('FL', '12049', 3, 113505),
    ('FL', '12051', 2, 98700),
    ('FL', '12051', 3, 113505),
    ('FL', '12053', 2, 114700),
    ('FL', '12053', 3, 131905),
    ('FL', '12055', 2, 98700),
    ('FL', '12055', 3, 113505),
    ('FL', '12057', 2, 114700),
    ('FL', '12057', 3, 131905),
    ('FL', '12059', 2, 98700),
    ('FL', '12059', 3, 113505),
    ('FL', '12061', 2, 102300),
    ('FL', '12061', 3, 117645),
    ('FL', '12063', 2, 98700),
    ('FL', '12063', 3, 113505),
    ('FL', '12065', 2, 101434),
    ('FL', '12065', 3, 116650),
    ('FL', '12067', 2, 98700),
    ('FL', '12067', 3, 113505),
    ('FL', '12069', 2, 114900),
    ('FL', '12069', 3, 132135),
    ('FL', '12071', 2, 112400),
    ('FL', '12071', 3, 129260),
    ('FL', '12073', 2, 101434),
    ('FL', '12073', 3, 116650),
    ('FL', '12075', 2, 98700),
    ('FL', '12075', 3, 113505),
    ('FL', '12077', 2, 98700),
    ('FL', '12077', 3, 113505),
    ('FL', '12079', 2, 98700),
    ('FL', '12079', 3, 113505),
    ('FL', '12081', 2, 114100),
    ('FL', '12081', 3, 131215),
    ('FL', '12083', 2, 100800),
    ('FL', '12083', 3, 117600),
    ('FL', '12085', 2, 114856),
    ('FL', '12085', 3, 132085),
    ('FL', '12086', 2, 136200),
    ('FL', '12086', 3, 156630),
    ('FL', '12087', 2, 171960),
    ('FL', '12087', 3, 200620),
    ('FL', '12089', 2, 108700),
    ('FL', '12089', 3, 125005),
    ('FL', '12091', 2, 113996),
    ('FL', '12091', 3, 131096),
    ('FL', '12093', 2, 98700),
    ('FL', '12093', 3, 113505),
    ('FL', '12095', 2, 114900),
    ('FL', '12095', 3, 132135),
    ('FL', '12097', 2, 114900),
    ('FL', '12097', 3, 132135),
    ('FL', '12099', 2, 128500),
    ('FL', '12099', 3, 147775),
    ('FL', '12101', 2, 114700),
    ('FL', '12101', 3, 131905),
    ('FL', '12103', 2, 114700),
    ('FL', '12103', 3, 131905),
    ('FL', '12105', 2, 103874),
    ('FL', '12105', 3, 119456),
    ('FL', '12107', 2, 98700),
    ('FL', '12107', 3, 113505),
    ('FL', '12109', 2, 108700),
    ('FL', '12109', 3, 125005),
    ('FL', '12111', 2, 114856),
    ('FL', '12111', 3, 132085),
    ('FL', '12113', 2, 102694),
    ('FL', '12113', 3, 118099),
    ('FL', '12115', 2, 114100),
    ('FL', '12115', 3, 131215),
    ('FL', '12117', 2, 114900),
    ('FL', '12117', 3, 132135),
    ('FL', '12119', 2, 104100),
    ('FL', '12119', 3, 119715),
    ('FL', '12121', 2, 98700),
    ('FL', '12121', 3, 113505),
    ('FL', '12123', 2, 98700),
    ('FL', '12123', 3, 113505),
    ('FL', '12125', 2, 98700),
    ('FL', '12125', 3, 113505),
    ('FL', '12127', 2, 101514),
    ('FL', '12127', 3, 116742),
    ('FL', '12129', 2, 101254),
    ('FL', '12129', 3, 116443),
    ('FL', '12131', 2, 115816),
    ('FL', '12131', 3, 133189),
    ('FL', '12133', 2, 98700),
    ('FL', '12133', 3, 113505)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_hlp_income_limits_nontargeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips and glv.household_size = v.household_size
);

-- Populate fl_hlp_income_limits_targeted
-- FL HLP Targeted -- 1-2 person / 3+ person, genuinely split in source.
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', 2, 124800),
    ('FL', '12001', 3, 145600),
    ('FL', '12003', 2, 120720),
    ('FL', '12003', 3, 140840),
    ('FL', '12005', 2, 118680),
    ('FL', '12005', 3, 138460),
    ('FL', '12007', 2, 118440),
    ('FL', '12007', 3, 138180),
    ('FL', '12009', 2, 119520),
    ('FL', '12009', 3, 139440),
    ('FL', '12011', 2, 152160),
    ('FL', '12011', 3, 177520),
    ('FL', '12013', 2, 118440),
    ('FL', '12013', 3, 138180),
    ('FL', '12015', 2, 118440),
    ('FL', '12015', 3, 138180),
    ('FL', '12017', 2, 118440),
    ('FL', '12017', 3, 138180),
    ('FL', '12019', 2, 130440),
    ('FL', '12019', 3, 152180),
    ('FL', '12021', 2, 145200),
    ('FL', '12021', 3, 169400),
    ('FL', '12023', 2, 118440),
    ('FL', '12023', 3, 138180),
    ('FL', '12027', 2, 118440),
    ('FL', '12027', 3, 138180),
    ('FL', '12029', 2, 118440),
    ('FL', '12029', 3, 138180),
    ('FL', '12031', 2, 130440),
    ('FL', '12031', 3, 152180),
    ('FL', '12033', 2, 118440),
    ('FL', '12033', 3, 138180),
    ('FL', '12035', 2, 125160),
    ('FL', '12035', 3, 146020),
    ('FL', '12037', 2, 118440),
    ('FL', '12037', 3, 138180),
    ('FL', '12039', 2, 119400),
    ('FL', '12039', 3, 139300),
    ('FL', '12041', 2, 124800),
    ('FL', '12041', 3, 145600),
    ('FL', '12043', 2, 118440),
    ('FL', '12043', 3, 138180),
    ('FL', '12045', 2, 118440),
    ('FL', '12045', 3, 138180),
    ('FL', '12047', 2, 118440),
    ('FL', '12047', 3, 138180),
    ('FL', '12049', 2, 118440),
    ('FL', '12049', 3, 138180),
    ('FL', '12051', 2, 118440),
    ('FL', '12051', 3, 138180),
    ('FL', '12053', 2, 137640),
    ('FL', '12053', 3, 160580),
    ('FL', '12055', 2, 118440),
    ('FL', '12055', 3, 138180),
    ('FL', '12057', 2, 137640),
    ('FL', '12057', 3, 160580),
    ('FL', '12059', 2, 118440),
    ('FL', '12059', 3, 138180),
    ('FL', '12061', 2, 122760),
    ('FL', '12061', 3, 143220),
    ('FL', '12063', 2, 118440),
    ('FL', '12063', 3, 138180),
    ('FL', '12065', 2, 119400),
    ('FL', '12065', 3, 139300),
    ('FL', '12067', 2, 118440),
    ('FL', '12067', 3, 138180),
    ('FL', '12069', 2, 137880),
    ('FL', '12069', 3, 160860),
    ('FL', '12071', 2, 134880),
    ('FL', '12071', 3, 157360),
    ('FL', '12073', 2, 119400),
    ('FL', '12073', 3, 139300),
    ('FL', '12075', 2, 118440),
    ('FL', '12075', 3, 138180),
    ('FL', '12077', 2, 118440),
    ('FL', '12077', 3, 138180),
    ('FL', '12079', 2, 118440),
    ('FL', '12079', 3, 138180),
    ('FL', '12081', 2, 136920),
    ('FL', '12081', 3, 159740),
    ('FL', '12083', 2, 118440),
    ('FL', '12083', 3, 138180),
    ('FL', '12085', 2, 122880),
    ('FL', '12085', 3, 143360),
    ('FL', '12086', 2, 163440),
    ('FL', '12086', 3, 190680),
    ('FL', '12087', 2, 171960),
    ('FL', '12087', 3, 200620),
    ('FL', '12089', 2, 130440),
    ('FL', '12089', 3, 152180),
    ('FL', '12091', 2, 128040),
    ('FL', '12091', 3, 149380),
    ('FL', '12093', 2, 118440),
    ('FL', '12093', 3, 138180),
    ('FL', '12095', 2, 137880),
    ('FL', '12095', 3, 160860),
    ('FL', '12097', 2, 137880),
    ('FL', '12097', 3, 160860),
    ('FL', '12099', 2, 154200),
    ('FL', '12099', 3, 179900),
    ('FL', '12101', 2, 137640),
    ('FL', '12101', 3, 160580),
    ('FL', '12103', 2, 137640),
    ('FL', '12103', 3, 160580),
    ('FL', '12105', 2, 118440),
    ('FL', '12105', 3, 138180),
    ('FL', '12107', 2, 118440),
    ('FL', '12107', 3, 138180),
    ('FL', '12109', 2, 130440),
    ('FL', '12109', 3, 152180),
    ('FL', '12111', 2, 122880),
    ('FL', '12111', 3, 143360),
    ('FL', '12113', 2, 118440),
    ('FL', '12113', 3, 138180),
    ('FL', '12115', 2, 136920),
    ('FL', '12115', 3, 159740),
    ('FL', '12117', 2, 137880),
    ('FL', '12117', 3, 160860),
    ('FL', '12119', 2, 124920),
    ('FL', '12119', 3, 145740),
    ('FL', '12121', 2, 118440),
    ('FL', '12121', 3, 138180),
    ('FL', '12123', 2, 118440),
    ('FL', '12123', 3, 138180),
    ('FL', '12125', 2, 118440),
    ('FL', '12125', 3, 138180),
    ('FL', '12127', 2, 118920),
    ('FL', '12127', 3, 138740),
    ('FL', '12129', 2, 120480),
    ('FL', '12129', 3, 140560),
    ('FL', '12131', 2, 118440),
    ('FL', '12131', 3, 138180),
    ('FL', '12133', 2, 118440),
    ('FL', '12133', 3, 138180)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_hlp_income_limits_targeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips and glv.household_size = v.household_size
);

-- 3. Populate purchase price limit rows (household_size left NULL -- doesn't vary by
--    household size. CONFIRM the column allows NULL before running; if it errors,
--    the fix is a single column-nullability change or a sentinel value swap, not a
--    data problem.)
-- Populate fl_housing_purchase_price_limits_nontargeted
-- Shared by FL Assist and FL HLP -- verified identical in source.
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', NULL::integer, 566354),
    ('FL', '12003', NULL::integer, 607645),
    ('FL', '12005', NULL::integer, 566354),
    ('FL', '12007', NULL::integer, 566354),
    ('FL', '12009', NULL::integer, 566354),
    ('FL', '12011', NULL::integer, 697889),
    ('FL', '12013', NULL::integer, 566354),
    ('FL', '12015', NULL::integer, 566354),
    ('FL', '12017', NULL::integer, 566354),
    ('FL', '12019', NULL::integer, 607645),
    ('FL', '12021', NULL::integer, 800166),
    ('FL', '12023', NULL::integer, 566354),
    ('FL', '12027', NULL::integer, 566354),
    ('FL', '12029', NULL::integer, 566354),
    ('FL', '12031', NULL::integer, 607645),
    ('FL', '12033', NULL::integer, 566354),
    ('FL', '12035', NULL::integer, 566354),
    ('FL', '12037', NULL::integer, 566354),
    ('FL', '12039', NULL::integer, 566354),
    ('FL', '12041', NULL::integer, 566354),
    ('FL', '12043', NULL::integer, 566354),
    ('FL', '12045', NULL::integer, 566354),
    ('FL', '12047', NULL::integer, 566354),
    ('FL', '12049', NULL::integer, 566354),
    ('FL', '12051', NULL::integer, 566354),
    ('FL', '12053', NULL::integer, 566354),
    ('FL', '12055', NULL::integer, 566354),
    ('FL', '12057', NULL::integer, 566354),
    ('FL', '12059', NULL::integer, 566354),
    ('FL', '12061', NULL::integer, 566354),
    ('FL', '12063', NULL::integer, 566354),
    ('FL', '12065', NULL::integer, 566354),
    ('FL', '12067', NULL::integer, 566354),
    ('FL', '12069', NULL::integer, 566354),
    ('FL', '12071', NULL::integer, 566354),
    ('FL', '12073', NULL::integer, 566354),
    ('FL', '12075', NULL::integer, 566354),
    ('FL', '12077', NULL::integer, 566354),
    ('FL', '12079', NULL::integer, 566354),
    ('FL', '12081', NULL::integer, 572751),
    ('FL', '12083', NULL::integer, 566354),
    ('FL', '12085', NULL::integer, 631710),
    ('FL', '12086', NULL::integer, 697889),
    ('FL', '12087', NULL::integer, 1036005),
    ('FL', '12089', NULL::integer, 607645),
    ('FL', '12091', NULL::integer, 631710),
    ('FL', '12093', NULL::integer, 566354),
    ('FL', '12095', NULL::integer, 566354),
    ('FL', '12097', NULL::integer, 566354),
    ('FL', '12099', NULL::integer, 697889),
    ('FL', '12101', NULL::integer, 566354),
    ('FL', '12103', NULL::integer, 566354),
    ('FL', '12105', NULL::integer, 566354),
    ('FL', '12107', NULL::integer, 566354),
    ('FL', '12109', NULL::integer, 607645),
    ('FL', '12111', NULL::integer, 631710),
    ('FL', '12113', NULL::integer, 566354),
    ('FL', '12115', NULL::integer, 572751),
    ('FL', '12117', NULL::integer, 566354),
    ('FL', '12119', NULL::integer, 566354),
    ('FL', '12121', NULL::integer, 566354),
    ('FL', '12123', NULL::integer, 566354),
    ('FL', '12125', NULL::integer, 566354),
    ('FL', '12127', NULL::integer, 566354),
    ('FL', '12129', NULL::integer, 566354),
    ('FL', '12131', NULL::integer, 631710),
    ('FL', '12133', NULL::integer, 566354)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_housing_purchase_price_limits_nontargeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips
  and glv.household_size is null
);

-- Populate fl_housing_purchase_price_limits_targeted
-- Shared by FL Assist and FL HLP -- verified identical in source.
insert into geo_lookup_values (lookup_table_id, state_code, county_fips, city_name, household_size, numeric_value, effective_date, source_url, last_verified_date)
select glt.id, v.state_code, v.county_fips, null, v.household_size, v.numeric_value, '2026-05-06'::date, NULL, '2026-07-31'::date
from geo_lookup_tables glt
join (values
    ('FL', '12001', NULL::integer, 692211),
    ('FL', '12003', NULL::integer, 742678),
    ('FL', '12005', NULL::integer, 692211),
    ('FL', '12007', NULL::integer, 692211),
    ('FL', '12009', NULL::integer, 692211),
    ('FL', '12011', NULL::integer, 852976),
    ('FL', '12013', NULL::integer, 692211),
    ('FL', '12015', NULL::integer, 692211),
    ('FL', '12017', NULL::integer, 692211),
    ('FL', '12019', NULL::integer, 742678),
    ('FL', '12021', NULL::integer, 977981),
    ('FL', '12023', NULL::integer, 692211),
    ('FL', '12027', NULL::integer, 692211),
    ('FL', '12029', NULL::integer, 692211),
    ('FL', '12031', NULL::integer, 742678),
    ('FL', '12033', NULL::integer, 692211),
    ('FL', '12035', NULL::integer, 692211),
    ('FL', '12037', NULL::integer, 692211),
    ('FL', '12039', NULL::integer, 692211),
    ('FL', '12041', NULL::integer, 692211),
    ('FL', '12043', NULL::integer, 692211),
    ('FL', '12045', NULL::integer, 692211),
    ('FL', '12047', NULL::integer, 692211),
    ('FL', '12049', NULL::integer, 692211),
    ('FL', '12051', NULL::integer, 692211),
    ('FL', '12053', NULL::integer, 692211),
    ('FL', '12055', NULL::integer, 692211),
    ('FL', '12057', NULL::integer, 692211),
    ('FL', '12059', NULL::integer, 692211),
    ('FL', '12061', NULL::integer, 692211),
    ('FL', '12063', NULL::integer, 692211),
    ('FL', '12065', NULL::integer, 692211),
    ('FL', '12067', NULL::integer, 692211),
    ('FL', '12069', NULL::integer, 692211),
    ('FL', '12071', NULL::integer, 692211),
    ('FL', '12073', NULL::integer, 692211),
    ('FL', '12075', NULL::integer, 692211),
    ('FL', '12077', NULL::integer, 692211),
    ('FL', '12079', NULL::integer, 692211),
    ('FL', '12081', NULL::integer, 700029),
    ('FL', '12083', NULL::integer, 692211),
    ('FL', '12085', NULL::integer, 772091),
    ('FL', '12086', NULL::integer, 852976),
    ('FL', '12087', NULL::integer, 1266228),
    ('FL', '12089', NULL::integer, 742678),
    ('FL', '12091', NULL::integer, 772091),
    ('FL', '12093', NULL::integer, 692211),
    ('FL', '12095', NULL::integer, 692211),
    ('FL', '12097', NULL::integer, 692211),
    ('FL', '12099', NULL::integer, 852976),
    ('FL', '12101', NULL::integer, 692211),
    ('FL', '12103', NULL::integer, 692211),
    ('FL', '12105', NULL::integer, 692211),
    ('FL', '12107', NULL::integer, 692211),
    ('FL', '12109', NULL::integer, 742678),
    ('FL', '12111', NULL::integer, 772091),
    ('FL', '12113', NULL::integer, 692211),
    ('FL', '12115', NULL::integer, 700029),
    ('FL', '12117', NULL::integer, 692211),
    ('FL', '12119', NULL::integer, 692211),
    ('FL', '12121', NULL::integer, 692211),
    ('FL', '12123', NULL::integer, 692211),
    ('FL', '12125', NULL::integer, 692211),
    ('FL', '12127', NULL::integer, 692211),
    ('FL', '12129', NULL::integer, 692211),
    ('FL', '12131', NULL::integer, 772091),
    ('FL', '12133', NULL::integer, 692211)
) as v(state_code, county_fips, household_size, numeric_value) on true
where glt.table_name = 'fl_housing_purchase_price_limits_targeted'
and not exists (
  select 1 from geo_lookup_values glv
  where glv.lookup_table_id = glt.id and glv.county_fips = v.county_fips
  and glv.household_size is null
);

-- 4. Point FL Assist's and FL HLP's income_threshold / financial_underwriting rules
--    at their correct dedicated tables (nontargeted default + targeted variant key).
--    Does NOT touch HFA Preferred/Advantage PLUS -- still pending its own source.

update program_eligibility_rules per
set rule_config = jsonb_build_object(
  'comparator', 'lte',
  'income_basis', 'household',
  'lookup_table', 'fl_assist_income_limits_nontargeted',
  'targeted_lookup_table', 'fl_assist_income_limits_targeted'
)
from programs p
where per.program_id = p.id
and p.name = 'Florida Assist (FL Assist)'
and per.rule_type = 'income_threshold';

update program_eligibility_rules per
set rule_config = jsonb_build_object(
  'field', 'purchase_price_cap',
  'lookup_table', 'fl_housing_purchase_price_limits_nontargeted',
  'targeted_lookup_table', 'fl_housing_purchase_price_limits_targeted'
)
from programs p
where per.program_id = p.id
and p.name = 'Florida Assist (FL Assist)'
and per.rule_type = 'financial_underwriting';

update program_eligibility_rules per
set rule_config = jsonb_build_object(
  'comparator', 'lte',
  'income_basis', 'household',
  'lookup_table', 'fl_hlp_income_limits_nontargeted',
  'targeted_lookup_table', 'fl_hlp_income_limits_targeted'
)
from programs p
where per.program_id = p.id
and p.name = 'Florida Homeownership Loan Program (FL HLP)'
and per.rule_type = 'income_threshold';

update program_eligibility_rules per
set rule_config = jsonb_build_object(
  'field', 'purchase_price_cap',
  'lookup_table', 'fl_housing_purchase_price_limits_nontargeted',
  'targeted_lookup_table', 'fl_housing_purchase_price_limits_targeted'
)
from programs p
where per.program_id = p.id
and p.name = 'Florida Homeownership Loan Program (FL HLP)'
and per.rule_type = 'financial_underwriting';
