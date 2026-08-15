-- Corrects Ohio Heroes' occupation_membership rule, which was created
-- with placeholder tags that don't match the real occupation_taxonomy
-- table (confirmed via check query 8/14/26). Decisions made explicitly:
--
-- 1. Veteran/active-duty/reserve -> the single reserved 'veteran' tag,
--    matched via buyer.veteranStatus by the code change in
--    evaluateOccupationMembership() (see matchingEngine.js), not a new
--    taxonomy row. Doesn't distinguish active-duty from reserve --
--    buyer_profiles has no field for that distinction.
-- 2. Physician/NP/LPN/STNA -> collapsed into the existing
--    'registered_nurse' tag. A physician or STNA selecting "Registered
--    Nurse" from the dropdown is inaccurate labeling, accepted as a
--    scope tradeoff rather than adding 4 new granular tags.
-- 3. School administrator/counselor -> collapsed into the existing
--    'teacher' tag, same tradeoff.
-- 4. law_enforcement_officer, firefighter, emt_paramedic -- renamed
--    from placeholder tags to their real taxonomy names (no new tags
--    needed, these already existed).
--
-- Ohio Heroes' description text is NOT changed -- it still accurately
-- describes the real OHFA-published occupation list. Only rule_config
-- (which drives actual matching) is corrected here; the gap between
-- "what the description says" and "what the dropdown can capture" is
-- the accepted, documented tradeoff above.

update program_eligibility_rules r
set rule_config = jsonb_set(
  rule_config,
  '{allowed_tags}',
  '["veteran", "law_enforcement_officer", "firefighter", "emt_paramedic", "registered_nurse", "teacher"]'::jsonb
) || jsonb_build_object(
  'note', 'Corrected 8/14/26 from placeholder tags (see homeaccessiq-check-occupation-taxonomy.sql). veteran = reserved tag matched via buyer.veteranStatus, not a taxonomy row. registered_nurse also covers physician/NP/LPN/STNA (collapsed for scope, per 8/14/26 decision); teacher also covers school administrators/counselors (same tradeoff).'
)
from programs p
where r.program_id = p.id
  and p.name = 'Ohio Heroes'
  and r.rule_type = 'occupation_membership'
returning p.name, r.rule_config->'allowed_tags' as corrected_tags, r.rule_config->>'note' as note;
