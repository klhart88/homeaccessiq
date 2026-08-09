// ============================================
// HomeAccessIQ -- Intake page DOM controller
// Wires intake.html's buttons/fields to js/intakeForm.js.
// Kept separate from intakeForm.js so that module stays
// UI-framework-agnostic (pure logic, testable on its own).
//
// Auth: this page is gated by authGuard.js (see <head> of
// intake.html), which redirects unauthenticated visitors to
// login.html before any of this runs. This controller no longer
// runs its own sign-in flow -- it just reads the already-confirmed
// session to grab the user's email for the follow-up request.
// ============================================

import {
  loadOccupations,
  geocodeBuyerLocations,
  saveBuyerProfile,
  runMatch,
  requestFollowUp
} from './intakeForm.js';
import { supabaseClient } from './supabaseClient.js';
import { formatPhoneNumber } from './leadCapture.js';

let currentUserEmail = '';

function showStep(stepId) {
  document.querySelectorAll('.step').forEach(el => el.classList.remove('active'));
  document.getElementById(stepId).classList.add('active');
}

// ---------- Input masking ----------

// Currency fields: reformat with comma thousands separators as the
// buyer types. Storing/parsing strips the commas back out on submit.
function attachCurrencyMask(inputId) {
  const el = document.getElementById(inputId);
  el.addEventListener('input', () => {
    const digitsOnly = el.value.replace(/[^\d]/g, '');
    el.value = digitsOnly === '' ? '' : Number(digitsOnly).toLocaleString('en-US');
  });
}
['household-income', 'borrower-only-income', 'target-price'].forEach(attachCurrencyMask);

// Phone: reformat live using the same helper the lead-capture flow
// already validates against, so both places agree on the format.
document.getElementById('followup-phone').addEventListener('input', (e) => {
  e.target.value = formatPhoneNumber(e.target.value);
});

// On load, grab the confirmed session's email for later use in the
// follow-up request. authGuard.js has already redirected away any
// visitor without a valid session before this code ever runs, so
// no branching/redirect logic is needed here -- just read and go.
(async () => {
  const { data: { session } } = await supabaseClient.auth.getSession();
  currentUserEmail = session?.user?.email || '';
  await populateOccupations();
  showStep('step-profile');
})();

async function populateOccupations() {
  const occupations = await loadOccupations();
  const select = document.getElementById('occupation-select');
  for (const occ of occupations) {
    const opt = document.createElement('option');
    opt.value = occ.tag;
    opt.textContent = occ.label;
    select.appendChild(opt);
  }
}

// ---------- Submit profile + run match ----------
document.getElementById('submit-profile-btn').addEventListener('click', async () => {
  const errorEl = document.getElementById('profile-error');
  errorEl.textContent = '';

  const purchaseAddress = document.getElementById('purchase-address').value;
  const residenceAddress = document.getElementById('residence-address').value;

  const formData = {
    householdIncome: numOrNull('household-income'),
    borrowerOnlyIncome: numOrNull('borrower-only-income'),
    householdSize: numOrNull('household-size'),
    isFirstTimeBuyer: document.getElementById('first-time-buyer').checked,
    veteranStatus: document.getElementById('veteran-status').checked,
    disabilityStatus: document.getElementById('disability-status').checked,
    occupationTag: document.getElementById('occupation-select').value || null,
    employerName: document.getElementById('employer-name').value || null,
    employerState: document.getElementById('employer-state').value.toUpperCase() || null,
    employerHoursPerWeek: numOrNull('employer-hours'),
    employerStartDate: document.getElementById('employer-start-date').value || null,
    employerPositionType: document.getElementById('employer-position-type').value || null,
    employerFacultyRank: document.getElementById('employer-faculty-rank').value || null,
    employerStaffGrade: numOrNull('employer-staff-grade'),
    employerIsHospitalPosition: document.getElementById('employer-is-hospital').checked,
    creditScore: numOrNull('credit-score'),
    dtiRatio: percentToDecimalOrNull('dti-ratio'),
    targetPurchasePrice: numOrNull('target-price')
  };

  try {
    document.getElementById('submit-profile-btn').textContent = 'Looking up your locations...';
    const locations = await geocodeBuyerLocations(residenceAddress, purchaseAddress);

    document.getElementById('submit-profile-btn').textContent = 'Saving your profile...';
    await saveBuyerProfile(formData, locations);

    document.getElementById('submit-profile-btn').textContent = 'Finding your matches...';
    const results = await runMatch();

    renderResults(results);
    showStep('step-results');
  } catch (err) {
    errorEl.textContent = err.message;
  } finally {
    document.getElementById('submit-profile-btn').textContent = 'See My Matches';
  }
});

function numOrNull(id) {
  const val = document.getElementById(id).value.replace(/,/g, '');
  return val === '' ? null : Number(val);
}

// DTI is entered as a whole-number percentage (e.g. 35) for a
// friendlier UX, but program_eligibility_rules stores/compares it
// as a decimal (0.35) -- convert here rather than asking buyers
// to do the math themselves.
function percentToDecimalOrNull(id) {
  const val = document.getElementById(id).value;
  return val === '' ? null : Number(val) / 100;
}

function renderResults(results) {
  const container = document.getElementById('results-list');
  container.innerHTML = '';

  // Two buckets, not four. Previously this function also split out
  // "needs more info" (had both unmetReasons and needsVerification)
  // and a bare "non-match" loop, to keep genuinely low-confidence
  // programs visually distinct from clean non-matches. As of 8/8/26,
  // matchingEngine.js's matchProgramsForBuyer() filters out any
  // program with unmetReasons.length > 0 before it's ever returned
  // here -- a deliberate design decision so buyers see only
  // confirmed matches and plausible pending-verification matches,
  // not the full non-match list (which would be overwhelming at
  // national program-count scale). Every result reaching this
  // function now has isMatch === true; needsVerification is what
  // distinguishes a confirmed match from a pending-verification one.
  const likelyMatches = results.filter(r =>
    r.needsVerification && r.needsVerification.length > 0
  );
  const matches = results.filter(r => !r.needsVerification || r.needsVerification.length === 0);

  if (matches.length === 0 && likelyMatches.length === 0) {
    const p = document.createElement('p');
    p.textContent = "We didn't find any programs you appear to qualify for based on what's on file. This may be worth a second look if your details change, or reach out below and we'll help you dig further.";
    container.appendChild(p);
  }

  for (const r of matches) {
    container.appendChild(buildResultCard(r, 'match'));
  }

  if (likelyMatches.length) {
    const heading = document.createElement('h2');
    heading.className = 'results-section-heading';
    heading.textContent = 'Likely matches — pending verification';
    container.appendChild(heading);

    const intro = document.createElement('p');
    intro.className = 'needs-review-intro';
    intro.textContent = "Your numbers check out for these programs, but at least one detail couldn't be fully confirmed. Worth investigating further -- see the specific open question below.";
    container.appendChild(intro);

    for (const r of likelyMatches) {
      container.appendChild(buildResultCard(r, 'likelyMatch'));
    }
  }
}

function buildResultCard(result, status) {
  const card = document.createElement('div');
  card.className = 'result-card ' + (status === 'likelyMatch' ? 'likely-match' : 'match');

  const title = document.createElement('h3');
  title.textContent = '\u2713 ' + result.program.name;
  card.appendChild(title);

  // Rate-only programs (e.g. IHCDA Step Down) provide no down
  // payment assistance at all -- just a below-market interest
  // rate. Flagged distinctly so it doesn't read like every other
  // dollar-amount program around it, regardless of match tier.
  if (result.program.program_type === 'rate_reduction') {
    const badge = document.createElement('span');
    badge.className = 'benefit-type-badge';
    badge.textContent = 'Interest rate discount — no down payment assistance';
    card.appendChild(badge);
  }

  const desc = document.createElement('p');
  desc.textContent = result.program.description || '';
  card.appendChild(desc);

  // unmetReasons is always empty on anything reaching this function
  // (see renderResults above) -- no longer rendered here. If that
  // invariant ever changes, this needs to come back.

  if (result.needsVerification.length) {
    const verify = document.createElement('p');
    verify.className = 'needs-verification';
    const prefix = status === 'likelyMatch' ? 'Pending confirmation: ' : "Can't confirm yet: ";
    verify.textContent = prefix + result.needsVerification.join('; ');
    card.appendChild(verify);
  }

  return card;
}

// ---------- Optional follow-up ----------
document.getElementById('request-followup-btn').addEventListener('click', async () => {
  const successEl = document.getElementById('followup-success');
  try {
    await requestFollowUp({
      email: currentUserEmail,
      name: document.getElementById('followup-name').value || null,
      phone: document.getElementById('followup-phone').value || null,
      notes: document.getElementById('followup-notes').value || null,
      requestType: 'question',
      sourcePage: 'intake.html'
    });
    successEl.textContent = "Thanks -- we'll be in touch.";
  } catch (err) {
    successEl.textContent = `Could not submit: ${err.message}`;
  }
});
