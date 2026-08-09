UPDATE program_eligibility_rules
SET rule_config = rule_config || jsonb_build_object(
  'targeted_tract_corroboration_note',
  'Two independent IHCDA documents (2020 and 2024) agree on this county''s tract boundaries.'
)
WHERE id IN (
  'e8622abe-b674-4429-a496-2eb2214b1f64', -- IHCDA First Step / income_threshold
  '3e15b2fc-31e9-4da5-a522-af5eb32ae44c', -- IHCDA First Step / financial_underwriting
  '748d6cf0-bb88-4f71-a1e6-60a133b2592c', -- IHCDA Next Home / income_threshold
  '93dde986-1383-4dee-aabe-a1839c923534', -- IHCDA Next Home / financial_underwriting
  '4f121a94-7487-495f-94b1-ca58816d51b7', -- IHCDA Step Down / income_threshold
  'ca00d106-34c4-46ea-a19e-834ea985883d'  -- IHCDA Step Down / financial_underwriting
)
RETURNING id, rule_type, rule_config->>'targeted_tract_corroboration_note' AS new_note;