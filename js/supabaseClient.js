// ============================================
// HomeAccessIQ — Supabase client
// (Net-new — no AreaIQ equivalent, since AreaIQ
// has no backend at all)
//
// Requires the Supabase JS CDN script to be loaded
// first in index.html:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
// which exposes the global `supabase` object.
// ============================================

import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

if (typeof window.supabase === 'undefined') {
  throw new Error(
    'Supabase JS SDK not loaded. Add the CDN <script> tag to index.html before this module runs.'
  );
}

// Single shared client instance for the whole app.
export const supabaseClient = window.supabase.createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY
);
