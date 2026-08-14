-- ============================================================
-- Kentucky Phase 1 -- KHC Secondary Market income limits, for
-- DPA's income_threshold rule (ky_khc_secondary_market_income_limits,
-- referenced but previously empty). Sourced 8/14/26 from KHC's
-- SMP Income Limitations PDF, effective 6/23/25.
--
-- Structurally different from MRB's data: ONE flat limit per
-- county (not split by household size 1-2/3+ like MRB). Stored
-- with household_size = null -- fetchGeoLookupValue's 'universal'
-- fallback already handles this shape (see the function's own
-- comment: 'others give bucketed thresholds... one code path
-- covers both shapes').
--
-- ky_khc_sam_income_limits is deliberately NOT populated here --
-- SAM's live page confirms income limits apply but the actual
-- table is in KHC's AllRegs (lender-authenticated, not publicly
-- accessible). Not reused from this table since SAM and Secondary
-- Market are different programs with no confirmed shared limits.
-- ============================================================

insert into geo_lookup_values (lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url)
select id, 'KY', v.county_fips, null, v.limit_value, '2025-06-23', 'https://www.kyhousing.org/Homeownership/Future-Homebuyers/Documents/SMP%20Income%20Limitations.pdf'
from geo_lookup_tables,
     (values
       ('21005', 162400),
       ('21117', 195650),
       ('21015', 195650),
       ('21143', 156275),
       ('21017', 179200),
       ('21151', 154700),
       ('21023', 195650),
       ('21145', 157850),
       ('21029', 169050),
       ('21149', 150850),
       ('21037', 195650),
       ('21163', 151900),
       ('21047', 153475),
       ('21167', 159075),
       ('21049', 179200),
       ('21179', 153125),
       ('21059', 150850),
       ('21185', 169050),
       ('21067', 179200),
       ('21191', 195650),
       ('21073', 161000),
       ('21209', 179200),
       ('21077', 195650),
       ('21211', 185150),
       ('21091', 148925),
       ('21215', 169050),
       ('21097', 148225),
       ('21221', 153475),
       ('21103', 169050),
       ('21229', 155750),
       ('21111', 169050),
       ('21239', 179200),
       ('21113', 179200),
       ('21001', 147350),
       ('21003', 147350),
       ('21007', 147350),
       ('21009', 147350),
       ('21011', 147350),
       ('21013', 147350),
       ('21019', 147350),
       ('21021', 147350),
       ('21025', 147350),
       ('21027', 147350),
       ('21031', 147350),
       ('21033', 147350),
       ('21035', 147350),
       ('21039', 147350),
       ('21041', 147350),
       ('21043', 147350),
       ('21045', 147350),
       ('21051', 147350),
       ('21053', 147350),
       ('21055', 147350),
       ('21057', 147350),
       ('21061', 147350),
       ('21063', 147350),
       ('21065', 147350),
       ('21069', 147350),
       ('21071', 147350),
       ('21075', 147350),
       ('21079', 147350),
       ('21081', 147350),
       ('21083', 147350),
       ('21085', 147350),
       ('21087', 147350),
       ('21089', 147350),
       ('21093', 147350),
       ('21095', 147350),
       ('21099', 147350),
       ('21101', 147350),
       ('21105', 147350),
       ('21107', 147350),
       ('21109', 147350),
       ('21115', 147350),
       ('21119', 147350),
       ('21121', 147350),
       ('21123', 147350),
       ('21125', 147350),
       ('21127', 147350),
       ('21129', 147350),
       ('21131', 147350),
       ('21133', 147350),
       ('21135', 147350),
       ('21137', 147350),
       ('21139', 147350),
       ('21141', 147350),
       ('21153', 147350),
       ('21155', 147350),
       ('21157', 147350),
       ('21159', 147350),
       ('21161', 147350),
       ('21147', 147350),
       ('21165', 147350),
       ('21169', 147350),
       ('21171', 147350),
       ('21173', 147350),
       ('21175', 147350),
       ('21177', 147350),
       ('21181', 147350),
       ('21183', 147350),
       ('21187', 147350),
       ('21189', 147350),
       ('21193', 147350),
       ('21195', 147350),
       ('21197', 147350),
       ('21199', 147350),
       ('21201', 147350),
       ('21203', 147350),
       ('21205', 147350),
       ('21207', 147350),
       ('21213', 147350),
       ('21217', 147350),
       ('21219', 147350),
       ('21223', 147350),
       ('21225', 147350),
       ('21227', 147350),
       ('21231', 147350),
       ('21233', 147350),
       ('21235', 147350),
       ('21237', 147350)
     ) as v(county_fips, limit_value)
where table_name = 'ky_khc_secondary_market_income_limits';

-- Verification
select count(*) as smp_rows_inserted from geo_lookup_values glv
join geo_lookup_tables glt on glt.id = glv.lookup_table_id
where glt.table_name = 'ky_khc_secondary_market_income_limits';

-- ============================================================
-- Correction: DPA and SAM's purchase_price_cap. Originally set
-- to $566,354 (KHC's general live Eligibility page). Two
-- independent official PDFs found since (Secondary Market SMP
-- Income Limitations, and MRB Household Income Limits -- both
-- effective 6/23/25) agree on $544,232 instead. Since DPA/SAM
-- ride on Secondary Market or MRB first mortgages, $544,232 is
-- the better-supported figure. Correcting rather than leaving
-- the earlier, weaker-sourced number in place.
-- ============================================================
update program_eligibility_rules r
set rule_config = rule_config || jsonb_build_object(
  'value', 544232,
  'note', 'Corrected 8/14/26: was 566354 (KHC general live Eligibility page). Two independent official KHC PDFs (Secondary Market SMP Income Limitations, MRB Household Income Limits -- both eff. 6/23/25) agree on $544,232 instead. DPA/SAM ride on Secondary Market or MRB first mortgages, both capped at $544,232 per those PDFs.'
)
from programs p
where r.program_id = p.id
  and p.name in ('KHC Down Payment Assistance (DPA)', 'Kentucky Shared Appreciation Mortgage (SAM)')
  and r.rule_type = 'financial_underwriting'
  and r.rule_config->>'field' = 'purchase_price_cap'
returning p.name, r.rule_config->>'value' as new_value;