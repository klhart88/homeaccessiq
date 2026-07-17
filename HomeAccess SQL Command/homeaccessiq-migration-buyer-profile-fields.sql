-- ============================================================
-- HomeAccessIQ — Migration: buyer_profiles additions
-- Run this in the SAME project (homeaccessiq) where the main
-- schema already exists. Purely additive — safe to run even
-- though buyer_profiles already has rows (there are none yet).
--
-- Why these are needed: building the matching engine surfaced
-- that `financial_underwriting` (purchase_price_cap) and
-- `employer_criteria` (hours/tenure) rules need buyer data that
-- wasn't in the original schema.
-- ============================================================

alter table buyer_profiles
  add column if not exists target_purchase_price numeric,
  add column if not exists employer_hours_per_week int,
  add column if not exists employer_start_date date;

-- employer_start_date lets tenure_days be computed at query time
-- (current_date - employer_start_date) rather than stored and
-- going stale.
