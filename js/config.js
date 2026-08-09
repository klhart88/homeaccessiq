// ============================================
// HomeAccessIQ — Configuration
// ============================================
// NOTE on key handling (different from AreaIQ):
// The Supabase anon key below is SAFE to expose in client-side
// code — Supabase's actual security boundary is Row Level
// Security (RLS), enforced server-side, not key secrecy. This
// is NOT the same situation as AreaIQ's Census/Mapbox/EmailJS
// keys, which needed domain-restriction as their only protection.
// Never put a Supabase SERVICE ROLE key here or anywhere
// client-side — that key bypasses RLS entirely.

export const SUPABASE_URL = 'https://cjlthzvyxxtjzzaugnjr.supabase.co'; // replace with homeaccessiq project URL
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqbHRoenZ5eHh0anp6YXVnbmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyNDc5MjMsImV4cCI6MjA5OTgyMzkyM30.2nS8vXNlxGXispSROEG_tgO16WNiyBqp6Jek9eaNopg'; // Project Settings > API in Supabase dashboard

// ---------- Reused from AreaIQ (geocode.js / census-block.js) ----------
// Same free/public government APIs, not state-specific — no
// changes needed for multi-state.
export const API_ENDPOINTS = {
  geocoder: 'https://nominatim.openstreetmap.org/search',
  censusACS: 'https://api.census.gov/data/2023/acs/acs5',
  fccCensusBlock: 'https://geo.fcc.gov/api/census/block/find'
};

// Only required if census-block.js/demographics lookups are reused;
// get your own key at api.census.gov/data/key_signup.html — do not
// reuse AreaIQ's committed key.
export const CENSUS_API_KEY = '905995c5580a85768b0657809bc932992ac3eb4f';

// ---------- Cache TTLs (in milliseconds) ----------
// Scope: non-sensitive reference data ONLY (program metadata,
// geocode results). Buyer eligibility profiles are never cached
// here — they live in Supabase, RLS-locked, per the PII boundary
// decision.
const ONE_DAY = 24 * 60 * 60 * 1000;

export const CACHE_TTL = {
  geocode: 30 * ONE_DAY,
  programMetadata: 1 * ONE_DAY   // programs' funding_status/last_verified_date change often enough
                                  // that a short TTL matters more here than it did for AreaIQ's
                                  // neighborhood data
};

// ---------- EmailJS credentials ----------
// Used ONLY by the lead-capture flow (contact info: name/email/
// phone/notes). Eligibility data (income, occupation, veteran
// status) must never be passed into these templates or params —
// see js/leadCapture.js for the enforced boundary.
export const EMAILJS_PUBLIC_KEY = 'jPK5MU0dLpEFzfbs4';
export const EMAILJS_SERVICE_ID = 'service_z3tj9um';
export const EMAILJS_TEMPLATE_ID = 'template_yenqe3g';

export const LEAD_NOTIFICATION_EMAIL = 'khart@fathomrealty.com'; // confirm/replace as needed
