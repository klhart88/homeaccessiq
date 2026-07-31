-- ============================================================
-- UK EAHP: real job-tier requirement + faculty tenure exemption
-- ============================================================
-- Source (primary, current): UK HR's own EAHP eligibility page --
-- https://hr.uky.edu/employment/employer-assisted-housing-program-eahp
--
-- "1) Regular full-time faculty at the rank of instructor or
-- assistant professor are eligible immediately upon receiving a
-- contract for the academic year, or 2) Regular full-time staff
-- employees at grade level 46 or below (grade 10 or below for
-- hospital positions) are eligible after completing the 90-day,
-- new employee orientation period."
--
-- Two real bugs this fixes:
-- 1. job_tier_min never actually existed in this rule's
--    rule_config -- the generic job_tier_min code path in
--    matchingEngine.js was dead code for this program. No job-tier
--    check was running at all.
-- 2. min_tenure_days: 90 was applied unconditionally to every
--    buyer, including faculty -- who are actually eligible
--    IMMEDIATELY per UK's own policy, no wait at all. This was a
--    live, real bug: a UK faculty member using the tool would be
--    incorrectly told they need a 90-day wait.
--
-- Also note: this is a MAXIMUM grade level (<=46 general, <=10
-- hospital), not a minimum -- "job_tier_min" as a field name is
-- backwards for this program's actual policy direction. Kept the
-- new field name (job_tier_requirement) generic/structured rather
-- than reusing the old misleading name.
--
-- Faculty eligibility is rank-restricted, not just "any faculty" --
-- only instructor and assistant professor rank qualify per the
-- source text above (more senior ranks aren't mentioned as
-- eligible). Loaded as stated; if that's not actually the full
-- picture, worth confirming with UK HR directly.
-- ============================================================

-- 1. New buyer_profiles columns -- nothing today captures
-- faculty-vs-staff status, rank, or grade level at all.
alter table buyer_profiles
  add column if not exists employer_position_type text,       -- 'faculty' | 'staff'
  add column if not exists employer_faculty_rank text,        -- e.g. 'instructor', 'assistant_professor'
  add column if not exists employer_staff_grade int,
  add column if not exists employer_is_hospital_position boolean default false;

-- 2. Update the UK EAHP employer_criteria rule_config.
do $$
declare
  v_program_id uuid;
  v_rule_id uuid;
begin
  select id into v_program_id
  from programs
  where name ilike '%Employer Assisted%' or name ilike '%EAHP%'
  limit 1;

  if v_program_id is null then
    raise exception 'Could not find UK EAHP program -- check programs.name';
  end if;

  select id into v_rule_id
  from program_eligibility_rules
  where program_id = v_program_id and rule_type = 'employer_criteria'
  limit 1;

  if v_rule_id is null then
    raise exception 'Could not find employer_criteria rule for UK EAHP';
  end if;

  update program_eligibility_rules
  set rule_config = rule_config || jsonb_build_object(
    'job_tier_requirement', jsonb_build_object(
      'faculty_ranks_eligible', jsonb_build_array('instructor', 'assistant_professor'),
      'staff_max_grade_general', 46,
      'staff_max_grade_hospital', 10
    ),
    'tenure_exempt_position_types', jsonb_build_array('faculty')
  )
  where id = v_rule_id;

  raise notice 'Updated UK EAHP employer_criteria rule % with job_tier_requirement and tenure exemption', v_rule_id;
end $$;
