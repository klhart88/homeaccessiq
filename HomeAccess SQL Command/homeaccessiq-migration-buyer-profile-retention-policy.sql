-- ============================================================
-- buyer_profiles retention policy: 1 year, hard delete
-- ============================================================
-- Decision (Kelvin, 2026-07-30): buyer_profiles data (income,
-- occupation, veteran/disability status, addresses) is retained
-- for 1 year after a buyer's LAST ACTIVITY, then hard-deleted.
--
-- "Last activity" = every time saveBuyerProfile() upserts a row
-- (updated_at changes), the retention window rolls forward another
-- year. This is a deliberate interpretation choice: the original
-- schema comment said retention was "set on creation," but the
-- decision as stated was based on last activity, not signup date --
-- flag if that's not actually what was intended.
--
-- Safe on lead_captures: buyer_profile_id is already
-- `on delete set null` (confirmed in schema, already commented
-- as intentional) -- a hard delete here does NOT remove your
-- contact/follow-up records, it just nulls the link.
--
-- Also handles the OTHER purge path the schema already anticipated
-- but nothing implements yet: `deleted_at`, for a future
-- buyer-initiated "delete my data" feature. Not built yet (no UI
-- calls this), but the column already existed with a documented
-- intent ("purges rows past retention_expires_at OR deleted_at +
-- grace period") -- built into the same job now so there's nothing
-- extra to do when that feature eventually gets a UI. Grace period
-- set to 30 days by default -- change if you want something
-- different.
-- ============================================================

-- 1. Backfill existing rows (there may be some from testing).
update buyer_profiles
set data_retention_expires_at = updated_at + interval '1 year'
where data_retention_expires_at is null;

-- 2. Trigger: roll the expiry forward on every insert/update.
create or replace function set_buyer_profile_retention()
returns trigger as $$
begin
  new.data_retention_expires_at := now() + interval '1 year';
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_buyer_profile_retention on buyer_profiles;
create trigger trg_buyer_profile_retention
before insert or update on buyer_profiles
for each row
execute function set_buyer_profile_retention();

-- 3. Scheduled purge job via pg_cron (standard Supabase extension).
-- NOTE: some Supabase projects require enabling pg_cron via the
-- Dashboard (Database -> Extensions) rather than SQL directly,
-- depending on plan/permissions. If the `create extension` line
-- below fails, enable it there first, then re-run just the
-- `select cron.schedule(...)` call.
create extension if not exists pg_cron;

select cron.schedule(
  'purge-expired-buyer-profiles',
  '0 3 * * *', -- daily at 3am UTC
  $$
  delete from buyer_profiles
  where data_retention_expires_at < now()
     or (deleted_at is not null and deleted_at < now() - interval '30 days');
  $$
);

-- Verify the job registered:
-- select * from cron.job where jobname = 'purge-expired-buyer-profiles';
