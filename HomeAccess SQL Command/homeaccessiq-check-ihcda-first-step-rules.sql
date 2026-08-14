-- Pulls every eligibility rule for IHCDA First Step, so we can see
-- exactly how its "first-time buyer required, unless purchasing in
-- a targeted census tract or an eligible veteran" exemption is
-- actually encoded -- rather than guess when building KY's MRB
-- rate-benefit program to match the same pattern.
SELECT p.name, r.id AS rule_id, r.rule_type, r.rule_config,
       r.exempts_rule_id, r.evaluation_order
FROM program_eligibility_rules r
JOIN programs p ON p.id = r.program_id
WHERE p.name = 'IHCDA First Step'
ORDER BY r.evaluation_order;
