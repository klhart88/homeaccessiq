-- ============================================================
-- HomeAccessIQ — Supabase Schema (v0.1)
-- ============================================================
-- Decisions closed (not assumptions — confirmed):
--   1. PII boundary: buyer_profiles data (income, occupation,
--      veteran/disability status, addresses) lives ONLY in
--      Supabase, RLS-locked to the owning user. It is NEVER
--      sent through EmailJS/Zapier — those channels are used
--      only by lead_captures (name/email/phone/notes), which
--      is a fully separate table.
--   2. Agent visibility: exactly one agent role exists today
--      (built as a table, not a hardcoded ID, so it can extend
--      to multiple agents later without a redesign). Agent
--      visibility into buyer_profiles is SCOPED to profiles
--      tied to an actual lead_capture row — using the matching
--      tool alone does not expose a buyer to the agent.
--   3. Multi-state is v1: geography is a lookup, not a hardcoded
--      column value, everywhere it appears.
--   4. Deterministic rule matching only (per eligibility-rule
--      spec v0.1) — no free-text/LLM interpretation needed.
-- ============================================================


-- ------------------------------------------------------------
-- 1. STATE REGISTRY
-- Replaces AreaIQ's hardcoded `if (state !== 'IN')` pattern.
-- Adding a state = inserting a row, not touching N JS files.
-- ------------------------------------------------------------
create table states (
  state_code      char(2) primary key,        -- 'IN', 'TN', 'KY', ...
  state_name      text not null,
  is_active       boolean not null default true,  -- data curated & live
  added_at        timestamptz not null default now()
);


-- ------------------------------------------------------------
-- 2. GEOGRAPHIC LOOKUP TABLES
-- Handles the "income limits aren't a single number" finding —
-- they vary by county (and sometimes household size).
-- Generic enough to hold income limits, purchase price caps,
-- or any other geography-keyed numeric threshold.
-- ------------------------------------------------------------
create table geo_lookup_tables (
  id              uuid primary key default gen_random_uuid(),
  table_name      text not null unique,        -- e.g. 'fl_hometown_heroes_county_limits'
  description     text,
  value_type      text not null,               -- 'income_limit' | 'purchase_price_cap' | other
  created_at      timestamptz not null default now()
);

create table geo_lookup_values (
  id                uuid primary key default gen_random_uuid(),
  lookup_table_id   uuid not null references geo_lookup_tables(id) on delete cascade,
  state_code        char(2) not null references states(state_code),
  county_fips       text,                      -- nullable: some rules are state-wide
  city_name         text,                      -- nullable: some are city-level
  household_size    int,                       -- nullable: some limits don't vary by household size
  numeric_value     numeric not null,          -- the actual threshold (dollar amount, %, etc.)
  effective_date    date not null,
  source_url        text,
  last_verified_date date not null default current_date
);

create index idx_geo_lookup_values_lookup ON geo_lookup_values(lookup_table_id, state_code, county_fips);


-- ------------------------------------------------------------
-- 3. OCCUPATION TAXONOMY
-- Maintained, versioned list — not a hardcoded enum.
-- ------------------------------------------------------------
create table occupation_taxonomy (
  id              uuid primary key default gen_random_uuid(),
  tag             text not null unique,        -- 'teacher', 'law_enforcement', 'veteran', ...
  label           text not null,               -- display name
  category        text,                        -- 'education' | 'public_safety' | 'military' | ...
  taxonomy_version text not null default 'v1',
  is_active       boolean not null default true
);


-- ------------------------------------------------------------
-- 4. PROGRAMS
-- ------------------------------------------------------------
create table programs (
  id                    uuid primary key default gen_random_uuid(),
  name                  text not null,
  administering_entity  text not null,          -- 'Alabama Housing Finance Authority', etc.
  program_type          text not null,          -- 'grant' | 'forgivable_loan' | 'deferred_loan' | 'tax_credit'
  description           text,
  source_url            text not null,
  funding_status        text not null default 'open',  -- 'open' | 'first_come_first_served' | 'exhausted' | 'seasonal'
  last_verified_date    date not null default current_date,
  stackable_with        uuid[] default '{}',    -- array of other program IDs; captured now, UI/logic deferred
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index idx_programs_funding_status on programs(funding_status);


-- ------------------------------------------------------------
-- 5. ELIGIBILITY RULES
-- One row per rule; rule_config holds type-specific fields
-- as jsonb rather than a wide sparse table (each rule_type
-- uses a different subset of fields, per the spec).
-- exemption_of_rule_id captures the "veteran exempts from
-- first-time-buyer" pattern — an exemption MODIFIES another
-- rule's evaluation, it isn't independent.
-- ------------------------------------------------------------
create type rule_type as enum (
  'income_threshold',
  'geographic_scope',
  'occupation_membership',
  'buyer_status',
  'employer_criteria',
  'financial_underwriting'
);

create table program_eligibility_rules (
  id                    uuid primary key default gen_random_uuid(),
  program_id            uuid not null references programs(id) on delete cascade,
  rule_type             rule_type not null,
  rule_config           jsonb not null,
  -- e.g. for income_threshold:
  --   {"ami_percent": 140, "comparator": "lte", "income_basis": "household",
  --    "geo_scope": "county", "lookup_table": "fl_hometown_heroes_county_limits"}
  -- e.g. for buyer_status:
  --   {"status_required": "first_time_buyer", "lookback_years": 3}

  exempts_rule_id       uuid references program_eligibility_rules(id),
  -- if set: satisfying THIS rule waives the referenced rule
  -- (e.g. an occupation_membership row for 'veteran' exempts
  -- the buyer_status 'first_time_buyer' row)

  evaluation_order      int not null default 0,
  -- rules with dependents (exemptions referencing them) must
  -- evaluate before their dependents; enforced in app logic,
  -- this column just makes the intended order explicit

  created_at            timestamptz not null default now()
);

create index idx_eligibility_rules_program on program_eligibility_rules(program_id);


-- ------------------------------------------------------------
-- 6. PROGRAM BENEFITS
-- Separate from eligibility — captures WHAT you get, which can
-- vary by which income tier you fall into (AHFA's tiered grant
-- is why this links to a rule rather than being a flat program
-- attribute).
-- ------------------------------------------------------------
create table program_benefits (
  id                uuid primary key default gen_random_uuid(),
  program_id        uuid not null references programs(id) on delete cascade,
  linked_rule_id    uuid references program_eligibility_rules(id),
  -- nullable: most programs have one flat benefit; AHFA-style
  -- tiered benefits link to the income_threshold rule that
  -- determines which tier applies

  benefit_type      text not null,       -- 'grant' | 'forgivable_loan' | 'rate_reduction' | 'tax_credit'
  amount_type       text not null,       -- 'flat' | 'percent_of_purchase_price'
  amount_value      numeric not null,
  max_amount        numeric,
  description       text
);


-- ------------------------------------------------------------
-- 7. PROGRAM REQUIREMENTS (closing gates, NOT eligibility filters)
-- Deliberately separate table per the eligibility spec finding:
-- homebuyer education, approved-lender-only, etc. gate closing,
-- not matching, and mixing them into rule evaluation pollutes
-- the matching query.
-- ------------------------------------------------------------
create table program_requirements (
  id                uuid primary key default gen_random_uuid(),
  program_id        uuid not null references programs(id) on delete cascade,
  requirement_type  text not null,     -- 'education_course' | 'approved_lender_only' | 'proof_document'
  description       text not null
);


-- ------------------------------------------------------------
-- 8. BUYER PROFILES
-- The sensitive table. RLS-locked (see policies below).
-- Two location fields per the residency-vs-purchase-location
-- finding — current residence is mostly informational (used
-- only for employer-zone checks), purchase_location drives
-- ~95% of matching.
-- Retention/deletion columns are real fields, not just policy
-- text — this was flagged as "still not written" in the
-- scaffolding checklist; this is where it becomes concrete.
-- ------------------------------------------------------------
create table buyer_profiles (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null references auth.users(id) on delete cascade,

  -- current residence (informational — employer-zone checks only)
  residence_state         char(2) references states(state_code),
  residence_county_fips   text,

  -- purchase location (drives matching)
  purchase_state          char(2) not null references states(state_code),
  purchase_county_fips    text,
  purchase_city           text,

  -- financial / eligibility fields
  household_income        numeric,
  borrower_only_income     numeric,
  household_size          int,
  credit_score            int,
  dti_ratio                numeric,

  -- status flags
  is_first_time_buyer     boolean,
  occupation_tag          text references occupation_taxonomy(tag),
  veteran_status          boolean default false,
  disability_status       boolean default false,

  -- employer (for employer-assisted programs)
  employer_name           text,
  employer_state          char(2) references states(state_code),

  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  -- retention / deletion — concrete fields, not just a policy doc
  data_retention_expires_at  timestamptz,   -- set on creation per your retention policy
  deleted_at                 timestamptz    -- soft delete; a scheduled job purges rows
                                             -- past retention_expires_at or deleted_at + grace period
);

alter table buyer_profiles enable row level security;

create policy "Users can view their own profile"
  on buyer_profiles for select
  using (auth.uid() = user_id);

create policy "Users can insert their own profile"
  on buyer_profiles for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own profile"
  on buyer_profiles for update
  using (auth.uid() = user_id);

create policy "Users can delete their own profile"
  on buyer_profiles for delete
  using (auth.uid() = user_id);


-- ------------------------------------------------------------
-- 9. AGENT ACCOUNTS
-- Built as a table, not a hardcoded user ID, even though
-- there's exactly one agent (you) today. Decision was:
-- sole admin now, but possibly opened to other agents if
-- this gets monetized later — this makes that a data change
-- (insert a row), not a schema/policy rewrite.
-- ------------------------------------------------------------
create table agent_accounts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  display_name  text not null,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- Helper used by policies below: is the current user an active agent?
create or replace function is_active_agent()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from agent_accounts
    where user_id = auth.uid() and is_active = true
  );
$$;


-- ------------------------------------------------------------
-- 10. LEAD CAPTURES
-- Contact-only PII (name/email/phone/notes) — same shape as
-- AreaIQ's existing EmailJS/Zapier flow, and the ONLY table
-- allowed to touch those channels. Deliberately separate from
-- buyer_profiles: eligibility fields never live here.
--
-- buyer_profile_id is nullable and is the consent boundary:
-- a profile only becomes visible to an agent (see policy
-- below) once its owner has actually submitted a lead capture
-- — using the matching tool alone does not expose anyone.
-- ------------------------------------------------------------
create table lead_captures (
  id                uuid primary key default gen_random_uuid(),
  buyer_profile_id  uuid references buyer_profiles(id) on delete set null,
  email             text not null,
  name              text,
  phone             text,
  notes             text,
  request_type      text not null,   -- 'results' | 'question', per AreaIQ's existing flow
  source_page       text,
  captured_at       timestamptz not null default now()
);

alter table lead_captures enable row level security;

-- Anyone can submit a lead capture (matches AreaIQ's public intake pattern)
create policy "Anyone can submit a lead capture"
  on lead_captures for insert
  with check (true);

-- Only the sole/active agent(s) can read lead captures
create policy "Agents can view lead captures"
  on lead_captures for select
  using (is_active_agent());


-- Agent visibility into buyer_profiles: SCOPED to profiles
-- that have an associated lead_capture row (i.e. the buyer
-- opted in by requesting results or asking a question).
-- A buyer who only ran the matching tool, without capturing
-- a lead, is not visible here.
create policy "Agents can view profiles tied to a lead capture"
  on buyer_profiles for select
  using (
    is_active_agent()
    and exists (
      select 1 from lead_captures
      where lead_captures.buyer_profile_id = buyer_profiles.id
    )
  );


-- ------------------------------------------------------------
-- 11. PUBLIC READ ACCESS for reference tables
-- Programs, rules, and lookup tables are not sensitive —
-- open for read, locked for write (writes go through a
-- service role / admin path, not exposed here).
-- ------------------------------------------------------------
alter table programs enable row level security;
create policy "Programs are publicly readable" on programs for select using (true);

alter table program_eligibility_rules enable row level security;
create policy "Rules are publicly readable" on program_eligibility_rules for select using (true);

alter table program_benefits enable row level security;
create policy "Benefits are publicly readable" on program_benefits for select using (true);

alter table program_requirements enable row level security;
create policy "Requirements are publicly readable" on program_requirements for select using (true);

alter table geo_lookup_values enable row level security;
create policy "Lookup values are publicly readable" on geo_lookup_values for select using (true);

alter table occupation_taxonomy enable row level security;
create policy "Occupation taxonomy is publicly readable" on occupation_taxonomy for select using (true);

alter table states enable row level security;
create policy "States are publicly readable" on states for select using (true);


-- ------------------------------------------------------------
-- Open items this schema does NOT resolve (flagging, not solving):
--   - Actual retention period (days/years) for buyer_profiles —
--     needs a real policy decision, this just gives it a column
--   - Whether match RESULTS get persisted (a buyer_matches table)
--     or computed fresh each time — deferred until intake form (Phase 5)
--   - Admin/write-path auth model for programs/rules tables —
--     assumed service-role-only for now, not modeled here
--   - How/when a buyer_profile_id gets attached to a lead_capture
--     row at submission time (app-layer logic, not schema) —
--     needs to happen in the intake/results-email flow (Phase 5)
--   - What happens if a buyer deletes their profile after a lead
--     capture exists — lead_captures.buyer_profile_id is set to
--     NULL (via ON DELETE SET NULL) so the lead record and its
--     contact info survive, but agent visibility into the (now
--     gone) eligibility profile disappears with it. Confirm this
--     is the behavior you want.
-- ------------------------------------------------------------
