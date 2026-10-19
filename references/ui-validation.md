# Rendered UI validation — 20 October 2026

Scope: the deployed disposable `nonprofit-readiness-demo` scratch org, native Microsoft Edge on macOS, Salesforce custom tab `/lightning/n/AI_Readiness`. Browser plugin/browser skill was unavailable; the available CUA native browser controls were used. This is live rendered evidence, separate from Node mapping checks and Apex tests.

## Desktop

The normal `sf org open` flow reached the clean Lightning custom-tab route with title **Lightning Experience | Salesforce**, app **Nonprofit AI Readiness**, and meaningful **AI Readiness** content. No framework error overlay was observed. Native-window screenshots were emitted in the validation session after authentication redirects completed; screenshots and raw login URLs were not added to the repository.

- **Run assessment** changed the initial prompt into live results: 25% data quality, 100% data-check coverage, 94 accessible Contacts, 55 missing email addresses, 10 possible repeated-email entries, and 60 Contacts without accounts. These are the current fictional scratch dataset's results, not customer measurements.
- After the runtime validation agent saved the first unknown-only review for this identity, a real browser refresh displayed **Latest own review: 0% score · 0% evidence coverage**, all seven exercises **Not assessed**, and **Evidence freshness assessed as of 2026-10-20; maximum age 30 days**. The review contained no confirmed observations, references or critical failures; it establishes no staff competence.
- A subsequent **Run assessment** displayed **Staff exercises: 0%**, **Checks completed: 0%. Your reviewed exercises only.**, and the individual unknown-evidence follow-ups. The overall text continued to withhold whole-team, safeguard and erasure readiness.
- Selecting **Apply an approved evidence age policy** and expanding the first exercise revealed assessment-date, maximum-age and observation-date controls. Date inputs were blank, action choices remained **Not observed**, and evidence/reference confirmations remained empty. This browser run did not save a review or create Tasks.
- Desktop screenshots showed readable text and no observed overlap in the inspected initial screen and saved-review summary. The entire long page, all date validation messages and all expanded exercises were not visually audited.

## Console

The inspected desktop console included three `net::ERR_BLOCKED_BY_CLIENT` resource errors for Salesforce instrumentation Beacon requests, with corresponding **Received Error Response from Beacon** messages. An enabled browser content blocker was visible. This supports an instrumentation-request failure, not a clean-console claim; no readiness-component exception was observed. Salesforce platform messages included a setup gate not preloaded. Additional warnings/issues were counted by DevTools but were not exhaustively expanded or classified.

## Phone-sized attempts

1. Edge DevTools **iPhone 16**, **393 × 852**: the already loaded desktop Lightning shell showed severe clipping/enlargement. Reloading under that mobile emulation redirected the custom-tab route to the scratch org's Salesforce Classic `/home/home.jsp`; the readiness page was absent. This records the observed route behavior only and does not establish an official Salesforce support restriction or a root cause.
2. Edge DevTools **Responsive**, **393 × 844**, explicitly **Desktop** device type: after returning to the Lightning custom-tab route and reloading, the readiness screen rendered at narrow width. The title, description and primary buttons wrapped within the inspected first viewport, and **Run assessment** produced a new checked timestamp plus the expected live results and unknown-only staff state in the accessibility tree. A screenshot showed readable initial-screen content. Staff-summary/form sections below the initial viewport were not visually verified at that width.

Mobile acceptance remains open. A narrow desktop-user-agent viewport does not establish the actual phone flow; the observed mobile-user-agent redirect needs investigation and a supported real-device/app entry path must be exercised. No workaround or frontend code change was introduced from this routing observation.

## Cleanup and remaining checks

Device emulation was verified disabled, DevTools was closed, and the clean desktop readiness route remained open. No observed pass/fail evidence was fabricated or saved during browser validation. Remaining work includes the actual phone entry route, complete small-screen staff form/layout, keyboard and screen-reader checks, date-validation rendering, and classification of the remaining console warnings.

## Focused-permission deployment smoke — 20 October 2026

After the final focused-role deployment, the existing authenticated Edge readiness tab was selected and refreshed without opening a new login flow. A safe projected CLI hostname comparison matched the observed browser host `ruby-java-7439.scratch.lightning.force.com` to the saved main org instance `ruby-java-7439.scratch.my.salesforce.com`; the saved Agentforce instance uses a different host. This confirms the org context, not the browser user. The authenticated browser user was not matched to the CLI identity, so this section describes the existing browser session only. **Run assessment** completed again (rendered last-checked time `20/10/2026, 01:47:37`): data quality remained 25% and the current own staff review showed 0% score and 0% coverage. The current latest review explicitly displayed **Evidence freshness not assessed. No observation-age policy was applied to this review.** This later observation does not replace the earlier separate policy-bearing review evidence.

For this existing identity, reviewer controls were present (**Apply an approved evidence age policy**, **Save staff review**), and no staff load error appeared. **Create my follow-up tasks** was absent from the complete accessibility tree; **Creating follow-up tasks requires Readiness Follow Up access.** was present. This directly verifies the rendered reviewer-without-follow-up-permission state. No review was saved, no Task action was invoked, and no permissions were changed during this smoke check. Summary-reader-only and assessor-only rendered browser states were not exercised in this run; their unit/native tests are separate evidence.
