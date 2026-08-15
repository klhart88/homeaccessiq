-- ============================================================
-- Fixes buyer_profiles_purchase_state_fkey blocking intake form
-- submission for any state not yet in the `states` table. Found
-- 8/15/26 via live retest: a Tennessee buyer profile failed to save
-- entirely (hard error, not a soft "no matches"), which meant GNND
-- -- and any future genuinely national program -- was never actually
-- reachable outside the handful of states already curated. This
-- directly undermined the point of curating national programs at
-- all.
--
-- states.is_active is explicitly commented "data curated & live" in
-- the schema -- a distinct concept from the FK constraint itself,
-- which only requires the row to EXIST. Adding every state now with
-- is_active = false (except the ones already curated) unblocks
-- submission everywhere immediately, without implying those states
-- have real program data yet.
--
-- ON CONFLICT DO NOTHING preserves whatever's already set for IN,
-- KY, OH (and FL, if already present) rather than overwriting.
-- ============================================================

insert into states (state_code, state_name, is_active) values
  ('AL', 'Alabama', false),
  ('AK', 'Alaska', false),
  ('AZ', 'Arizona', false),
  ('AR', 'Arkansas', false),
  ('CA', 'California', false),
  ('CO', 'Colorado', false),
  ('CT', 'Connecticut', false),
  ('DE', 'Delaware', false),
  ('DC', 'District of Columbia', false),
  ('FL', 'Florida', true),
  ('GA', 'Georgia', false),
  ('HI', 'Hawaii', false),
  ('ID', 'Idaho', false),
  ('IL', 'Illinois', false),
  ('IN', 'Indiana', true),
  ('IA', 'Iowa', false),
  ('KS', 'Kansas', false),
  ('KY', 'Kentucky', true),
  ('LA', 'Louisiana', false),
  ('ME', 'Maine', false),
  ('MD', 'Maryland', false),
  ('MA', 'Massachusetts', false),
  ('MI', 'Michigan', false),
  ('MN', 'Minnesota', false),
  ('MS', 'Mississippi', false),
  ('MO', 'Missouri', false),
  ('MT', 'Montana', false),
  ('NE', 'Nebraska', false),
  ('NV', 'Nevada', false),
  ('NH', 'New Hampshire', false),
  ('NJ', 'New Jersey', false),
  ('NM', 'New Mexico', false),
  ('NY', 'New York', false),
  ('NC', 'North Carolina', false),
  ('ND', 'North Dakota', false),
  ('OH', 'Ohio', true),
  ('OK', 'Oklahoma', false),
  ('OR', 'Oregon', false),
  ('PA', 'Pennsylvania', false),
  ('RI', 'Rhode Island', false),
  ('SC', 'South Carolina', false),
  ('SD', 'South Dakota', false),
  ('TN', 'Tennessee', false),
  ('TX', 'Texas', false),
  ('UT', 'Utah', false),
  ('VT', 'Vermont', false),
  ('VA', 'Virginia', false),
  ('WA', 'Washington', false),
  ('WV', 'West Virginia', false),
  ('WI', 'Wisconsin', false),
  ('WY', 'Wyoming', false)
on conflict (state_code) do nothing;

-- Verification
select state_code, state_name, is_active from states order by state_code;
select count(*) as total_states, count(*) filter (where is_active) as curated_states from states;
