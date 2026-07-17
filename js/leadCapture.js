// ============================================
// HomeAccessIQ — Lead Capture module
// (Adapted from AreaIQ's leadcapture.js — UI/UX
// pattern reused, but data path changed)
//
// *** OPEN DECISION — FLAGGING, NOT DECIDING HERE ***
// AreaIQ wrote leads to Zapier -> Airtable as the CRM
// of record. HomeAccessIQ's agent-visibility policy
// (see Supabase schema, program_eligibility_rules doc)
// depends on a lead_captures ROW EXISTING IN SUPABASE,
// since that's what scopes your visibility into
// buyer_profiles. This draft writes to Supabase directly
// and treats it as the record of truth; Zapier/Airtable
// is stubbed out below (commented) in case you still want
// a parallel copy in your existing CRM. Confirm before
// building further on this.
//
// PII BOUNDARY: only contact fields (email/name/phone/
// notes) are handled here. Never pass buyer_profile
// eligibility fields (income, occupation, veteran status)
// into this module or into EmailJS.
// ============================================

import { supabaseClient } from './supabaseClient.js';
import {
  EMAILJS_PUBLIC_KEY,
  EMAILJS_SERVICE_ID,
  EMAILJS_TEMPLATE_ID,
  LEAD_NOTIFICATION_EMAIL
} from './config.js';

if (typeof emailjs !== 'undefined') {
  emailjs.init({ publicKey: EMAILJS_PUBLIC_KEY });
}

// Public entry point. Call after a buyer profile has been
// created/saved, so buyerProfileId can link the two records
// (this is what makes them visible to you as an agent).
//
// contactInfo: { email, name, phone, notes, requestType, sourcePage }
export async function submitLeadCapture(contactInfo, buyerProfileId = null) {
  const { data, error } = await supabaseClient
    .from('lead_captures')
    .insert({
      buyer_profile_id: buyerProfileId,
      email: contactInfo.email,
      name: contactInfo.name || null,
      phone: contactInfo.phone || null,
      notes: contactInfo.notes || null,
      request_type: contactInfo.requestType, // 'results' | 'question'
      source_page: contactInfo.sourcePage || null
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Could not save your request: ${error.message}`);
  }

  // Notify the agent by email (contact info only — no eligibility data)
  if (typeof emailjs !== 'undefined') {
    try {
      await emailjs.send(EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, {
        lead_email: contactInfo.email,
        lead_name: contactInfo.name || '(not provided)',
        lead_phone: contactInfo.phone || '(not provided)',
        lead_notes: contactInfo.notes || '(no notes)',
        request_type: contactInfo.requestType,
        to_email: LEAD_NOTIFICATION_EMAIL
      });
    } catch (emailErr) {
      // Non-fatal — the Supabase row is the record of truth;
      // email is a convenience notification only.
      console.warn('Lead notification email failed:', emailErr);
    }
  }

  return data;
}

// ---------- Helpers reused conceptually from AreaIQ ----------

export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function formatPhoneNumber(value) {
  const digits = String(value || '').replace(/\D/g, '').slice(0, 10);
  if (!digits) return '';
  if (digits.length < 4) return `(${digits}`;
  if (digits.length < 7) return `(${digits.slice(0, 3)}) ${digits.slice(3)}`;
  return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
}
