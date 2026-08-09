# HomeAccessIQ — Lead Capture, Archive & Results Delivery
**Status:** Real agent authentication built and confirmed working. RLS verified. Auto-purge, results email, and archive lookup still pending.
**Date:** August 6, 2026 (originally drafted); updated same day after access-control implementation
**Author context:** Decisions below were made in conversation to resolve the open question flagged directly in the existing `leadCapture.js` code comments. This document exists so the reasoning survives even if the chat that produced it doesn't.

---

## 1. Background

HomeAccessIQ already has:
- A live intake form (multi-section: location, household, income, employer, financial) — actively being expanded as new state/county down-payment assistance programs are curated. Field set is expected to keep changing.
- A results page ("See My Matches") — not yet built out to collect contact info.
- A `config.js` and `leadCapture.js` already drafted, pointing at Supabase (not Airtable/Zapier).

The draft `leadCapture.js` contained an explicit open decision:

> *AreaIQ wrote leads to Zapier → Airtable as the CRM of record. HomeAccessIQ's agent-visibility policy depends on a `lead_captures` row existing in Supabase... Confirm before building further on this.*

This document resolves that decision and the follow-up questions it raised.

---

## 2. Decision: No CRM — Supabase is the sole system of record

**Reasoning:**
- HomeAccessIQ collects sensitive financial data (income, credit score, debt-to-income, employer details) under a stated ~90-day deletion policy in the app's disclaimer.
- A CRM implies indefinite retention and active pipeline management — directly at odds with a short, enforced retention window.
- The app is agent-only (Kelvin Hart), never used for client self-entry, and is explicitly *not* a customer-facing lead-capture surface in the way AreaIQ/AffordabilityIQ are. Lead capture for HomeAccessIQ happens *after* the lead already exists through another channel.

**Implication:** The Zapier/Airtable stub referenced in `leadCapture.js`'s comments should be removed, not just left commented out — it's not a parallel option under consideration, it's ruled out.

---

## 3. Decision: 90-day auto-purge, not manual deletion

**Reasoning:** A compliance policy that depends on someone remembering to delete data manually is weak. Since Supabase is Postgres, retention can be enforced automatically.

**Not yet implemented — needs building:**
- A scheduled job (Supabase's built-in `pg_cron` extension, or a Supabase Edge Function on a timer) that deletes any `buyer_profiles` / `lead_captures` row older than 90 days from creation.
- Recommend the job targets `buyer_profiles` first (the record holding eligibility/financial data) and lets a `ON DELETE CASCADE` foreign key relationship clean up the linked `lead_captures` row automatically, rather than deleting the two tables separately and risking them drifting out of sync.
- **Open question for implementation:** confirm the 90-day figure against the actual disclaimer text on the live site before building the job — this doc assumes ~90 days per the conversation, but the job should match whatever the disclaimer legally commits to, exactly.

---

## 4. Decision: Follow-up lookup by client email address

For a follow-up session with a prospect, the agent will search Supabase by the client's email address to pull the archived `buyer_profiles` / `lead_captures` record back up.

**Not yet implemented — needs building:**
- A simple internal lookup view/query (could be as lightweight as a Supabase Table Editor filter, or a small internal search page) — no separate archive system needed, since the auto-purge (Section 3) already makes Supabase itself the time-boxed archive.
- Confirm `email` is indexed on `lead_captures` and/or `buyer_profiles` for reasonable lookup performance as the table grows.

---

## 5. Access control: real Supabase Auth login (replaced Cloudflare Access OTP)

**Original state:** HomeAccessIQ sat behind Cloudflare Access, OTP-gated, configured to send codes only to Kelvin Hart's email — matching the pattern used for NegotiatorIQ.

**Why this changed:** During RLS verification (see 5a below), it became clear that `is_active_agent()` — the function every RLS policy on this project depends on — checks `auth.uid()`, which requires a genuine Supabase Auth session. Cloudflare Access's OTP gate never produced one. In effect, **the RLS boundary was correctly designed but non-functional**, since nothing ever logged into Supabase itself. This was caught before the app held any real client data.

Separately, Kelvin decided to make this change regardless of the RLS issue: the app should require real login rather than OTP, both to simplify his own access (no waiting on an email code) and to support a branded landing/login page instead of Cloudflare's interstitial.

**5a. RLS verification — confirmed sound:**
- `buyer_profiles` and `lead_captures` both have RLS enabled with named policies (not permissive defaults).
- Underlying function `is_active_agent()` checks: `select exists (select 1 from agent_accounts where user_id = auth.uid() and is_active = true)` — a real identity check, not a hardcoded bypass.
- `buyer_profiles` SELECT policy additionally requires the row to be linked to an existing `lead_captures` record before an agent can view it.
- **Conclusion:** the policies themselves are correctly designed. The only gap was the missing real-auth session to make `auth.uid()` resolve to anything — which is what Section 5b below fixes.

**5b. What was built:**
- One real Supabase Auth user created (`kelvin@smartiqrealty.com`), linked via `user_id` to a matching row in `agent_accounts` with `is_active = true`.
- "Allow new users to sign up" disabled in Supabase Auth settings — this one account is the only one that will ever exist.
- `login.html` — branded sign-in page (SmartIQ Realty styling), calls `supabase.auth.signInWithPassword()`.
- `authGuard.js` — imported at the top of any page that should require login; checks for a valid session via `supabase.auth.getSession()`, redirects to `login.html` if none exists. This is the real security boundary now, replacing Cloudflare Access.
- `reset-password.html` — dedicated page to catch Supabase's password-recovery link and let the agent set a new password, since Supabase's recovery flow otherwise has nowhere valid to land. Listens specifically for the `PASSWORD_RECOVERY` auth event (not just "any session exists") before allowing a password update, and signs out the temporary recovery session afterward to force a clean real login.
- Supabase **Site URL** corrected from a leftover `localhost:8000` (a dev-environment artifact) to the live domain, initially pointed at `reset-password.html` specifically so recovery links land somewhere that can act on them.

**5c. Deployment lessons worth remembering** (cost real time today, documenting so it doesn't repeat):
- **Relative import paths resolve against the page's served URL, not the file's location in the repo.** `index.html` sits at repo root while `authGuard.js`/`supabaseClient.js` sit in `js/` — every cross-reference between them needs an absolute path (`/js/supabaseClient.js`), not a relative one (`./supabaseClient.js`), or it silently 404s depending on which page is loading it.
- **Duplicate copies of the same file in different folders are a real hazard, not just clutter.** A stray second copy of `login.html` in `js/` (alongside the intended root copy) caused a one-time 404 after login, because that copy's relative redirect resolved to `js/index.html`, which doesn't exist. Fix was deleting the duplicate, not patching the redirect.
- **The Supabase JS SDK CDN `<script>` tag must load before any module that imports `supabaseClient.js`.** This was missing from `index.html`, `intake.html`, and `login.html` at various points and produced a clear, well-labeled error each time once found — worth checking any *new* page added later remembers this tag too.

**5d. Second, deeper bug found and fixed: two competing auth systems on `intake.html`.**

`intake.html` had been independently built earlier with its own complete, self-contained Supabase **email OTP** login (Steps "step-email"/"step-otp": enter email → get a 6-digit code → verify) — a legitimate, working design at the time, predating today's password-login work. Once `authGuard.js` was added to gate the page, it created a real, working session — but `intake.html`'s own `intake-controller.js` still only marked a user as signed in via its OTP-specific `verifyLoginCode()` function, which never ran anymore. Net effect: `authGuard.js` correctly let the user onto the page, the page correctly skipped straight to the intake form, but submitting it failed with "Not signed in" — because `intakeForm.js`'s `saveBuyerProfile()` was checking a local module variable that only the now-dead OTP path ever set, not the real session that actually existed.

**Fix:** removed the OTP flow entirely rather than patching around it — one auth system for the whole app, not two overlapping ones.
- `intake.html`: `step-email` and `step-otp` sections deleted; the profile form is now the first thing shown, since `authGuard.js` already guarantees a session exists before the page is reachable.
- `intake-controller.js`: OTP button wiring removed; now just reads the confirmed session's email once (for the follow-up form) instead of running its own sign-in flow.
- `intakeForm.js`: `sendLoginCode()`, `verifyLoginCode()`, `getCurrentUser()`, and the stale `currentUser` variable removed. `saveBuyerProfile()` now checks the live session directly via `supabaseClient.auth.getUser()` instead of trusting a variable that only one of two auth paths ever populated.
- Also corrected a stale comment in the old `intakeForm.js` describing the access model as "a deliberate open self-serve signup: anyone who reaches the site can request a code and create an account" — that was accurate when OTP was the whole system, but is no longer true or intended now that signups are disabled and Kelvin is the only account.
- Retested end-to-end three times post-fix: login, form submission, and results rendering all confirmed working with no errors.

**Still open:**
- Cloudflare Access policy in front of the domain has not yet been disabled — recommend leaving both running in parallel a while longer given how much iteration the auth flow needed today, then retiring Cloudflare Access once confident.
- The `lead_captures` INSERT policy ("Anyone can submit a lead capture") was flagged as worth tightening to also require `is_active_agent()`, now that Kelvin is the only legitimate submitter — **not yet done.**
- Minor cosmetic-only item, low priority: both `index.html` and `intake.html` briefly flash their real content for an instant before `authGuard.js`'s redirect fires, since the redirect is JS-driven rather than blocking initial paint. Not a security issue (no data loads until interacted with), just a visual flicker — could be smoothed later with a loading state instead of showing real markup by default.

---

## 6. Decision: Results delivery via EmailJS, mirroring NegotiatorIQ

**Reasoning:** NegotiatorIQ already has a confirmed-working EmailJS setup sending as `khart@fathomrealty.com` (verified alias, working correctly — unlike the Make.com Gmail module used elsewhere, which has a known bug ignoring custom From addresses). Reusing this pattern is lower-effort and proven, versus building a new Make.com scenario from scratch.

**⚠️ Open item — needs verification:**

The `EMAILJS_SERVICE_ID` (`service_z3tj9um`) and `EMAILJS_TEMPLATE_ID` (`template_yenqe3g`) currently in `config.js` have not been confirmed to exist as real, configured services in the EmailJS dashboard — they may be placeholders drafted ahead of actual setup. **Before wiring anything further, log into EmailJS and confirm:**
1. Does a service with ID `service_z3tj9um` actually exist, and is it connected (same reconnect check we did for AreaIQ/NegotiatorIQ)?
2. Does a template with ID `template_yenqe3g` exist, and does its content match what a "results delivered to client" email should say (currently `leadCapture.js` only sends *notification* fields to the agent — `lead_email`, `lead_name`, `lead_phone`, `lead_notes`, `request_type` — it does not yet send an actual results email *to the client*, unlike AffordabilityIQ/AreaIQ's dual-template pattern).

**Gap identified:** as currently drafted, `leadCapture.js` only notifies the agent that a request came in — it does **not** email results to the client. Given the stated priority ("my concern for this one will certainly be configuring the results email delivery"), a second EmailJS template + send call (client-facing, containing results — but never the underlying eligibility/financial inputs per the PII boundary already established in the code comments) will need to be added, following the same pattern as AffordabilityIQ's `sendResultsEmail()`.

---

## 7. PII boundary — already correctly designed, worth preserving

The existing code comments already establish a rule worth keeping explicit as this gets built out further:

> Only contact fields (email/name/phone/notes) are handled in `leadCapture.js` / EmailJS. Eligibility fields (income, occupation, veteran status, credit score, etc.) must never be passed into EmailJS templates or params.

This is a good boundary and should be maintained when the client-facing results template (Section 6 gap) is built — results language can describe *outcomes* ("You may qualify for X program") without echoing back raw sensitive inputs in the email body.

---

## 8. Summary of what's confirmed vs. still open

| Item | Status |
|---|---|
| No CRM / Airtable / Zapier for HomeAccessIQ | ✅ Decided |
| Supabase as sole system of record | ✅ Decided |
| Lookup method for follow-up: by email | ✅ Decided |
| Supabase RLS actually enforces agent-only access | ✅ Verified — policies correctly check `is_active_agent()` / `auth.uid()` |
| Real Supabase Auth login (replacing Cloudflare OTP) | ✅ Built and confirmed working across multiple browsers |
| Password reset flow (`reset-password.html`) | ✅ Built and confirmed working |
| `intake.html`'s competing OTP auth system removed | ✅ Fixed — one consistent auth path app-wide; end-to-end tested 3x with no errors |
| Retention: is it actually 90 days? | ⬜ **Corrected to 1 year** — matches program timelines better than the originally-assumed 90 days; live disclaimer text still needs to match this |
| 90-day (now 1-year) auto-purge via `pg_cron`/Edge Function | ⬜ Not built — `data_retention_expires_at` is stamped on each row via `set_buyer_profile_retention` trigger, but nothing yet reads it and deletes expired rows |
| `lead_captures` INSERT policy tightened to require `is_active_agent()` | ⬜ Not done — currently open to "anyone" |
| Disable Cloudflare Access policy (now redundant with real login) | ⬜ Not done — intentionally left running in parallel for now |
| EmailJS service/template IDs in config.js are real and connected | ✅ Verified — `service_z3tj9um` and `template_yenqe3g` both exist in EmailJS dashboard |
| Client-facing results email (not just agent notification) | ⬜ Not built — current template only notifies the agent |
| Remove commented Zapier/Airtable stub from leadCapture.js | ⬜ Not done |
| Internal lookup view/page for archived profiles by email | ⬜ Not built |