// ============================================
// HomeAccessIQ — Auth Guard
//
// Import this at the very top of any page that
// should require a logged-in agent (index.html,
// results page, any admin/lookup view). Redirects
// to login.html if there's no valid session.
//
// This REPLACES the Cloudflare Access OTP gate —
// once this is live and confirmed working, the
// Cloudflare Access policy in front of this domain
// should be disabled, not left running alongside it.
// ============================================

import { supabaseClient } from './supabaseClient.js';

export async function requireAgentSession() {
  const { data: { session }, error } = await supabaseClient.auth.getSession();

  if (error || !session) {
    window.location.href = './login.html';
    return null;
  }

  return session;
}

// Optional: call this from a "Sign out" button anywhere in the app
export async function signOutAgent() {
  await supabaseClient.auth.signOut();
  window.location.href = './login.html';
}

// Run immediately on import so protected pages never
// flash their content before the redirect happens
requireAgentSession();
