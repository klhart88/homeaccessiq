-- ============================================================
-- Migration: one buyer_profiles row per user
-- Surfaced while building the real intake form -- without this,
-- a returning buyer resubmitting the form creates a duplicate
-- row instead of updating their existing one.
-- ============================================================

alter table buyer_profiles
  add constraint buyer_profiles_user_id_unique unique (user_id);
