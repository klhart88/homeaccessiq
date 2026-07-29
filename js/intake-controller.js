// ============================================
// HomeAccessIQ -- Intake page DOM controller
// Wires intake.html's buttons/fields to js/intakeForm.js.
// Kept separate from intakeForm.js so that module stays
// UI-framework-agnostic (pure logic, testable on its own).
// ============================================

import {
  sendLoginCode,
  verifyLoginCode,
  loadOccupations,
  geocodeBuyerLocations,
  saveBuyerProfile,
  runMatch,
  requestFollowUp
} from './intakeForm.js';
import { supabaseClient } from './supabaseClient.js';
import { formatPhoneNumber } from './leadCapture.js';

let pendingEmail = '';

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

// Access model (locked): Supabase OTP only, no external gate.
// On load, check whether a session already exists -- this covers
// the case where the buyer clicked the email's confirmation LINK
// instead of typing the code (supabase-js auto-detects the
// access_token in the URL and establishes a session from it).
// Without this check, a link-click would silently strand them on
// the email-entry step even though they're actually signed in.
(async () => {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    await populateOccupations();
    showStep('step-profile');
  } else {
    showStep('step-email');
  }
})();

// ---------- Step 1: send code ----------
document.getElementById('send-code-btn').addEventListener('click', async () => {
  const email = document.getElementById('email-input').value.trim();
  const errorEl = document.getElementById('email-error');
  errorEl.textContent = '';
  try {
    await sendLoginCode(email);
    pendingEmail = email;
    showStep('step-otp');
  } catch (err) {
    errorEl.textContent = err.message;
  }
});

// ---------- Step 2: verify code ----------
document.getElementById('verify-code-btn').addEventListener('click', async () => {
  const code = document.getElementById('otp-input').value.trim();
  const errorEl = document.getElementById('otp-error');
  errorEl.textContent = '';
  try {
    await verifyLoginCode(pendingEmail, code);
    await populateOccupations();
    showStep('step-profile');
  } catch (err) {
    errorEl.textContent = err.message;
  }
});

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

// ---------- Step 3: submit profile + run match ----------
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

  const matches = results.filter(r => r.isMatch);
  const nonMatches = results.filter(r => !r.isMatch);

  if (matches.length === 0) {
    const p = document.createElement('p');
    p.textContent = "We didn't find a confirmed match yet, but see the notes below -- some programs need a bit more info from you.";
    container.appendChild(p);
  }

  for (const r of matches) {
    container.appendChild(buildResultCard(r, true));
  }
  for (const r of nonMatches) {
    container.appendChild(buildResultCard(r, false));
  }
}

function buildResultCard(result, isMatch) {
  const card = document.createElement('div');
  card.className = isMatch ? 'result-card match' : 'result-card no-match';

  const title = document.createElement('h3');
  title.textContent = (isMatch ? '\u2713 ' : '') + result.program.name;
  card.appendChild(title);

  const desc = document.createElement('p');
  desc.textContent = result.program.description || '';
  card.appendChild(desc);

  if (!isMatch && result.unmetReasons.length) {
    const reasons = document.createElement('p');
    reasons.className = 'unmet-reasons';
    reasons.textContent = 'Not currently eligible: ' + result.unmetReasons.join('; ');
    card.appendChild(reasons);
  }

  if (result.needsVerification.length) {
    const verify = document.createElement('p');
    verify.className = 'needs-verification';
    verify.textContent = 'Needs more info: ' + result.needsVerification.join('; ');
    card.appendChild(verify);
  }

  return card;
}

// ---------- Step 4: optional follow-up ----------
document.getElementById('request-followup-btn').addEventListener('click', async () => {
  const successEl = document.getElementById('followup-success');
  try {
    await requestFollowUp({
      email: pendingEmail,
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
