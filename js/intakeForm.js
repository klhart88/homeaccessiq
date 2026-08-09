// ============================================
// HomeAccessIQ -- Intake form orchestration
//
// Access model: gated by authGuard.js (real Supabase Auth
// password login via login.html) on every protected page,
// including this one. This module no longer manages its own
// sign-in state -- it looks up the current authenticated user
// directly from Supabase when needed, rather than tracking a
// local currentUser variable that only OTP verification used to
// populate. Signups are disabled at the Supabase project level;
// Kelvin's is the only account that will ever exist.
// ============================================

import { supabaseClient } from './supabaseClient.js';
import { geocodeAddress } from './geocode.js';
import { matchProgramsForBuyer } from './matchingEngine.js';
import { submitLeadCapture } from './leadCapture.js';

let currentProfile = null;

// ---------- Occupation list for the dropdown ----------

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

// ---------- Geocode both location fields ----------

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

// ---------- Save profile (upsert -- one row per buyer) ----------

// formData shape matches the intake.html form fields directly.
export async function saveBuyerProfile(formData, locations) {
  const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
  if (userError || !user) throw new Error('Not signed in.');

  const profileRow = {
    user_id: user.id,

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
    employer_position_type: formData.employerPositionType || null,
    employer_faculty_rank: formData.employerFacultyRank || null,
    employer_staff_grade: formData.employerStaffGrade || null,
    employer_is_hospital_position: formData.employerIsHospitalPosition || false,

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

// ---------- Run the match ----------

export async function runMatch() {
  if (!currentProfile) throw new Error('No profile saved yet.');
  return matchProgramsForBuyer(currentProfile);
}

export function getCurrentProfile() {
  return currentProfile;
}

// ---------- Optional follow-up request ----------

export async function requestFollowUp(contactInfo) {
  if (!currentProfile) throw new Error('No profile saved yet.');
  return submitLeadCapture(contactInfo, currentProfile.id);
}
