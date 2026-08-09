-- Migration: Add missing state-scope gate to IHCDA Step Down and Next Home
-- Verified 2026-07-31 via Florida-address test profile.
--
-- BUG: When Step Down and Next Home were cloned from First Step's rule rows,
-- the base state_scope geographic_scope rule (scope_level: "state",
-- allowed_values: ["IN"]) was NOT copied over -- only the county-level
-- targeted-area geographic_scope rule was. This meant a Florida (or any
-- non-Indiana) purchase address showed Step Down/Next Home as
-- "Likely matches -- pending verification" instead of correctly being
-- blocked for purchase location outside program's state scope, exactly
-- as First Step already handles correctly.
--
-- Fix: add the same state_scope rule First Step already has
-- (rule_id ba552906-b46c-4e81-959a-d55b40d4e8b2, exempts_rule_id null,
-- i.e. applies to everyone regardless of first-time-buyer/veteran/targeted-
-- area status -- Indiana-only programs stay Indiana-only no matter what).
--
-- evaluation_order -10 is used so this runs before every existing rule on
-- both programs (Next Home's lowest existing order is 0; Step Down's is 0
-- for its first-time-buyer check) -- a state-scope failure is a hard gate,
-- not something that should be short-circuited by other rule ordering.

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
values
  (
    (select id from programs where name = 'IHCDA Step Down'),
    'geographic_scope',
    '{"scope_level":"state","allowed_values":["IN"]}'::jsonb,
    null,
    -10
  ),
  (
    (select id from programs where name = 'IHCDA Next Home'),
    'geographic_scope',
    '{"scope_level":"state","allowed_values":["IN"]}'::jsonb,
    null,
    -10
  );
