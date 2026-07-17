-- ============================================================
-- Fix: geo_lookup_tables was missing a public-read RLS policy.
-- Every other reference table got one in the original schema;
-- this one was accidentally skipped, causing silent (no-error)
-- empty results for anon/authenticated roles -- confirmed via
-- debug logging showing {tableRow: null, tableError: null}.
-- ============================================================

alter table geo_lookup_tables enable row level security;

create policy "Lookup tables are publicly readable"
  on geo_lookup_tables for select
  using (true);
