// ============================================
// HomeAccessIQ — State registry
// (Net-new — replaces AreaIQ's pattern of a
// hardcoded `if (location.state !== 'IN')` check
// repeated in every module (schools.js, tax.js).
//
// That pattern was fine for a single-state app,
// but HomeAccessIQ is multi-state from v1 — adding
// a state should be a data operation (insert a row
// into `states` in Supabase), not a code change
// across every feature module.
// ============================================

import { supabaseClient } from './supabaseClient.js';
import { cacheGet, cacheSet } from './cache.js';
import { CACHE_TTL } from './config.js';

const CACHE_KEY = 'state-registry:active-states';

// Returns an array of active state codes, e.g. ['IN', 'TN', 'FL'].
// Cached briefly since this rarely changes within a session but
// isn't hardcoded — reflects whatever's actually marked active
// in Supabase.
export async function getActiveStates() {
  const cached = cacheGet(CACHE_KEY);
  if (cached) return cached;

  const { data, error } = await supabaseClient
    .from('states')
    .select('state_code, state_name')
    .eq('is_active', true);

  if (error) {
    console.error('Failed to load state registry:', error);
    return [];
  }

  cacheSet(CACHE_KEY, data, CACHE_TTL.programMetadata);
  return data;
}

// Convenience check — replaces the old `if (state !== 'IN')` pattern.
// Usage: if (!(await isStateActive(location.state))) { ...not in service area... }
export async function isStateActive(stateCode) {
  const activeStates = await getActiveStates();
  return activeStates.some(s => s.state_code === stateCode);
}
