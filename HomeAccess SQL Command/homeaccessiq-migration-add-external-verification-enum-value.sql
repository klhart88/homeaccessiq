-- The GNND insert failed because rule_type is a Postgres ENUM type
-- (create type rule_type as enum (...)), not free text -- adding a
-- case to matchingEngine.js's switch statement doesn't add a new
-- value to the database's enum constraint. This adds it there too.
--
-- Note: ALTER TYPE ... ADD VALUE cannot run inside the same
-- transaction as a statement that USES the new value (a Postgres
-- restriction on enum additions) -- run this as its own statement,
-- separately, before re-running the GNND program_eligibility_rules
-- insert.
ALTER TYPE rule_type ADD VALUE 'external_verification';

-- Verification -- confirms the enum now has 7 values
SELECT enumlabel FROM pg_enum
WHERE enumtypid = 'rule_type'::regtype
ORDER BY enumsortorder;
