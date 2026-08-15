-- ============================================================
-- HUD Good Neighbor Next Door (GNND) -- first genuinely national
-- program curated (8/14/26). No geographic_scope rule at all --
-- deliberate, since this is federal and applies in every state,
-- unlike every program curated so far.
--
-- Uses the new external_verification rule_type: occupation and
-- program terms ARE fully computable eligibility (no ambiguity),
-- but property availability is a live-inventory question the app
-- can't represent as a static fact. See matchingEngine.js's
-- evaluateExternalVerification() and its surrounding comment for
-- the full reasoning on why this differs from targetedTractCaveat.
--
-- Sourced from HUD.gov directly (hud.gov/helping-americans/good-
-- neighbor) plus corroborating current program terms (50% discount,
-- 36-month occupancy, silent second mortgage structure).
-- ============================================================

insert into programs (id, name, administering_entity, program_type, description, source_url, funding_status, last_verified_date)
values (
  '79f31f1c-d468-47f7-8cce-fc33d57a7081',
  'HUD Good Neighbor Next Door (GNND)',
  'U.S. Department of Housing and Urban Development',
  'forgivable_loan',
  'Purchase a HUD-owned home at 50% off its list price in a HUD-designated revitalization area. The discount is structured as a silent second mortgage with no payments or interest, forgiven in full after 36 months of owner-occupancy as your primary residence (leaving early requires repaying a prorated share). Usable with FHA (as low as $100 down on the discounted price), VA, conventional, or USDA financing. Eligible occupations: full-time law enforcement officers, pre-K-12 teachers, and firefighters/EMTs. National program -- available in every state, not administered by any state housing finance agency. Listings are HUD-owned properties specifically, not any home on the market, and inventory is limited and changes weekly.',
  'https://www.hud.gov/helping-americans/good-neighbor',
  'open',
  current_date
);

insert into program_eligibility_rules (id, program_id, rule_type, rule_config, evaluation_order)
values
  ('7e6646c0-9ac6-4f83-b2de-686ec69b6d57', '79f31f1c-d468-47f7-8cce-fc33d57a7081', 'occupation_membership',
   '{"allowed_tags": ["law_enforcement_officer", "teacher", "firefighter", "emt_paramedic"], "match_mode": "any_of"}', 0),
  ('98617a3a-e761-4260-bf7d-163e90906776', '79f31f1c-d468-47f7-8cce-fc33d57a7081', 'external_verification',
   '{"message": "GNND applies only to specific HUD-owned homes currently listed in a designated revitalization area -- this match reflects your occupation and the program''s eligibility terms, not whether a qualifying home is available right now. Listings are limited (often fewer than 5 active per area at any time) and change weekly. Search HUD''s Homestore portal (hudhomestore.gov) for current listings in your target area, and confirm the specific property is GNND-eligible before proceeding. Requires 36 months of owner-occupancy as your primary residence."}', 1);

-- Verification
select p.name, r.rule_type, r.rule_config
from programs p
join program_eligibility_rules r on r.program_id = p.id
where p.name = 'HUD Good Neighbor Next Door (GNND)'
order by r.evaluation_order;
