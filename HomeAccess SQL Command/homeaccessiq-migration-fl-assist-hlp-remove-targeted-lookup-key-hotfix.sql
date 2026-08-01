-- Hotfix: Remove 'targeted_lookup_table' key from FL Assist / FL HLP rule_config.
--
-- WHY: Retest (7/31/26, 11:14 PM, Miami-Dade FL address) showed FL Assist and FL HLP
-- surfacing this caveat instead of a real pass/fail:
--   "This county has a targeted census tract per IHCDA's current program, but
--    HomeAccessIQ has no tract boundary data on file for it -- verify targeted-area
--    status directly with IHCDA."
-- This is factually wrong -- IHCDA is Indiana's housing finance agency and has no
-- relationship to a Florida property. HFA Preferred/Advantage PLUS (whose rule_config
-- was NOT touched by the prior migration) still shows the old, unrelated placeholder
-- caveat -- confirming the 'targeted_lookup_table' key itself is what triggers a
-- shared "check targeted census tract" code path in the matching engine that was
-- built for IHCDA and has "IHCDA" hardcoded into its message rather than
-- parameterized by state/program. This migration removes that key so FL Assist/HLP
-- stop walking into that code path until it's properly generalized (or a
-- FL-specific targeted-tract check is built using the census tract list already on
-- file from the Bond Guide's "FEDERALLY DESIGNATED TARGETED AREAS" section).
--
-- EFFECT: FL Assist and FL HLP income_threshold / financial_underwriting rules will
-- go back to checking ONLY the nontargeted lookup tables for every county -- same
-- conservative direction as before (never wrongly denies a real buyer; may
-- under-serve a targeted-area buyer whose real limit is higher, until targeted-area
-- matching is built properly). Real pass/fail should now show correctly using the
-- populated nontargeted data.
--
-- FOLLOW-UP NEEDED (next session): find and read the matching-engine code (likely
-- intake-controller.js) for whatever function produces this IHCDA-tract-boundary
-- caveat, confirm whether the message string is hardcoded to "IHCDA" or templated,
-- and either (a) generalize it to reference the correct state/agency per program, or
-- (b) build real FL targeted-tract matching using the tract list already extracted
-- from the Bond Guide, then re-add 'targeted_lookup_table' once that's working.

update program_eligibility_rules per
set rule_config = rule_config - 'targeted_lookup_table'
from programs p
where per.program_id = p.id
and p.name = 'Florida Assist (FL Assist)'
and per.rule_type in ('income_threshold', 'financial_underwriting')
and per.rule_config ? 'targeted_lookup_table';

update program_eligibility_rules per
set rule_config = rule_config - 'targeted_lookup_table'
from programs p
where per.program_id = p.id
and p.name = 'Florida Homeownership Loan Program (FL HLP)'
and per.rule_type in ('income_threshold', 'financial_underwriting')
and per.rule_config ? 'targeted_lookup_table';
