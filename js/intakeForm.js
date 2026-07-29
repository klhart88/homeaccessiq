// ============================================
// HomeAccessIQ -- Intake form orchestration
//
// Access model (locked): Supabase email OTP is the ONLY access
// mechanism -- no Cloudflare or other edge-level gate. This is a
// deliberate open self-serve signup: anyone who reaches the site
// can request a code and create an account. No password anywhere;
// the code itself IS the login.
// ============================================

import { supabaseClient } from './supabaseClient.js';
import { geocodeAddress } from './geocode.js';
import { matchProgramsForBuyer } from './matchingEngine.js';
import { submitLeadCapture, isValidEmail } from './leadCapture.js';

let currentUser = null;
let currentProfile = null;

// ---------- Step 1: passwordless email sign-in ----------

export async function sendLoginCode(email) {
  if (!isValidEmail(email)) throw new Error('Please enter a valid email address.');
  const { error } = await supabaseClient.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: true }
  });
  if (error) throw new Error(`Could not send code: ${error.message}`);
}

export async function verifyLoginCode(email, code) {
  const { data, error } = await supabaseClient.auth.verifyOtp({
    email,
    token: code,
    type: 'email'
  });
  if (error) throw new Error(`Invalid or expired code: ${error.message}`);
  currentUser = data.user;
  return currentUser;
}

export function getCurrentUser() {
  return currentUser;
}

// ---------- Step 2: occupation list for the dropdown ----------

export async function loadOccupations() {
  const { data, error } = await supabaseClient
    .from('occupation_taxonomy')
    .select('tag, label, category')
    .eq('is_active', true)
    .order('category', { ascending: true });
  if (error) {
    console.warn('Could not load occupations:', error);
    return [];
  }
  return data;
}

// ---------- Step 3: geocode both location fields ----------

// Returns { residence: LocationContext, purchase: LocationContext }
// Either can be null if the buyer left that field blank (residence
// is optional for most programs; purchase is required).
export async function geocodeBuyerLocations(residenceAddress, purchaseAddress) {
  const result = { residence: null, purchase: null };

  if (residenceAddress && residenceAddress.trim()) {
    result.residence = await geocodeAddress(residenceAddress);
  }
  if (purchaseAddress && purchaseAddress.trim()) {
    result.purchase = await geocodeAddress(purchaseAddress);
  } else {
    throw new Error('Purchase location is required to find matching programs.');
  }

  return result;
}

// ---------- Step 4: save profile (upsert -- one row per buyer) ----------

// formData shape matches the intake.html form fields directly.
export async function saveBuyerProfile(formData, locations) {
  if (!currentUser) throw new Error('Not signed in.');

  const profileRow = {
    user_id: currentUser.id,

    residence_state: locations.residence?.state || null,
    residence_county_fips: locations.residence?.countyFips || null,

    purchase_state: locations.purchase.state,
    purchase_county_fips: locations.purchase.countyFips,
    purchase_city: locations.purchase.city,
    purchase_census_tract: locations.purchase.censusTract,

    household_income: formData.householdIncome || null,
    borrower_only_income: formData.borrowerOnlyIncome || null,
    household_size: formData.householdSize || null,
    credit_score: formData.creditScore || null,
    dti_ratio: formData.dtiRatio || null,
    target_purchase_price: formData.targetPurchasePrice || null,

    is_first_time_buyer: formData.isFirstTimeBuyer,
    occupation_tag: formData.occupationTag || null,
    veteran_status: formData.veteranStatus || false,
    disability_status: formData.disabilityStatus || false,

    employer_name: formData.employerName || null,
    employer_state: formData.employerState || null,
    employer_hours_per_week: formData.employerHoursPerWeek || null,
    employer_start_date: formData.employerStartDate || null,

    updated_at: new Date().toISOString()
  };

  const { data, error } = await supabaseClient
    .from('buyer_profiles')
    .upsert(profileRow, { onConflict: 'user_id' })
    .select()
    .single();

  if (error) throw new Error(`Could not save your profile: ${error.message}`);
  currentProfile = data;
  return data;
}

// ---------- Step 5: run the match ----------

export async function runMatch() {
  if (!currentProfile) throw new Error('No profile saved yet.');
  return matchProgramsForBuyer(currentProfile);
}

export function getCurrentProfile() {
  return currentProfile;
}

// ---------- Step 6: optional follow-up request ----------

export async function requestFollowUp(contactInfo) {
  if (!currentProfile) throw new Error('No profile saved yet.');
  return submitLeadCapture(contactInfo, currentProfile.id);
}
