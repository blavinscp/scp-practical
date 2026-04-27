# SCP Technical Architect Practical Exam

Welcome. This is a **30-minute design exercise** — no coding, no scratch org, no deployments. We're looking for how you think about integration architecture on the Salesforce platform: the patterns you pick, the risks you anticipate, and how clearly you can communicate your design under time pressure.

| Time | Activity |
|------|----------|
| 0–5 min | **Code review** — read the 2 artifacts listed in [Part 1](#part-1-code-review-5-min), note the issues |
| 5–15 min | **Integration design** — whiteboard your architecture for the scenario below |
| 15–30 min | **Walkthrough** — discuss your code review findings and design with the interviewer |

---

## Part 1: Code Review (~5 min)

Review two artifacts in the repo. Each one contains at least one anti-pattern or bug. For each artifact, be ready to:

- **Name the issue(s)** — what's wrong?
- **Explain the risk** — what breaks at scale, in production, or under load?
- **Describe the fix** — what would you change and why?

You don't need to write any code — just read and prepare to discuss.

| # | Artifact | Location | What it does |
|---|----------|----------|-------------|
| 1 | **ContactTrigger** | `force-app/main/default/triggers/ContactTrigger.trigger` | An Apex trigger on Contact that maintains a `Contact_Count__c` rollup on Account. |
| 2 | **Account_Stamp_Region flow** | `force-app/main/default/flows/Account_Stamp_Region.flow-meta.xml` | A record-triggered flow on Account that stamps a `Region__c` field based on `BillingState`. It maps CA/OR/WA → "West", NY/NJ → "East", everything else → "Other". |

---

## Part 2: Integration Design (~10 min)

### Scenario: Provider Onboarding & Verification

SCP Health is building a new Provider Onboarding workflow. A credentialing clerk submits a clinician's identifying details through a guided intake. The system must:

1. **Intake.** Capture the clinician's name, NPI, primary state license number, license state, and specialty.
2. **NPI validation (sync).** Validate the NPI against NPPES (the federal provider registry). Some NPIs will be invalid; some calls will fail transiently.
3. **Primary source verification (async).** Submit the record to a Primary Source Verification (PSV) service that takes minutes to hours to complete. PSV returns a job handle immediately and eventually produces a PASS/FAIL result.
4. **Fan-out (event).** When verification passes, mark the Provider record `Verified` and publish a platform event so downstream systems can react.

```
  Clerk
   |
   v
+---------+   sync    +---------------+
|  Intake |---------->| NPPES lookup  |
+---------+           +---------------+
   |
   v
+----------------+   submit    +-----------+
|  Provider__c   |------------>|    PSV    |
|  (Pending)     |             +-----------+
+----------------+                  |
   ^                                | 
   |                                v 
   |                           (PASS/FAIL)
   |                                |
   |               +----------------+
   v               v
+----------------+    publish    +---------------------+
|  Provider__c   |-------------->| Provider_Onboarded__e|
|  (Verified)    |               +---------------------+
+----------------+
```

### Your deliverables

1. **Architecture diagram.** Whiteboard your end-to-end design. Any tool — draw.io, Excalidraw, Miro, Lucidchart, pen and paper. We care about the thinking, not the polish.
2. **Decision bullets.** Short notes on your key choices: which integration patterns, how you handle errors and retries, how you handle idempotency, what goes on the platform event payload, and how you reason about PHI/security.

### System context

You won't build or deploy anything for this exercise. The object and fields below are described so you have a concrete contract to design against.

**`Provider__c` custom object (assumed to exist):**

| Field | Type | Notes |
|-------|------|-------|
| `Name` | Auto Number `PRV-{00000}` | |
| `NPI__c` | Text(10), External ID, Unique | |
| `License_Number__c` | Text(40) | |
| `License_State__c` | Picklist | 5 US states |
| `Specialty__c` | Picklist | 4 values (Family Medicine, Emergency Medicine, Hospitalist, Cardiology) |
| `Status__c` | Picklist | `Draft`, `Intake_Complete`, `Verification_Pending`, `Verified`, `Rejected` |
| `Verification_Job_Id__c` | Text(64), External ID | |
| `Verified_At__c` | DateTime | |
| `Verification_Failure_Reason__c` | Long Text Area | |

---

## Part 3: Walkthrough (~15 min)

The interviewer will drive the discussion. Be ready to cover:

- **Code review findings** — walk through what you found in each artifact.
- **Integration patterns.** Why sync vs async vs event-driven at each step? What's your fallback when upstream is slow or unreachable?
- **Error handling & retry.** What happens when NPPES is down? When PSV takes two days? When a callback never arrives?
- **Idempotency.** What if the same NPI is submitted twice in the same minute? What if a PSV callback arrives three times?
- **Data modeling.** Does the state machine on `Status__c` capture every transition? What breaks if someone resubmits during verification?
- **Event design.** What's on the platform event payload and why only those fields? How do consumers handle replay?
- **PHI / security.** Which fields are sensitive? Where does sensitive data end up in logs? How do you prove field-level access at audit time?
- **Observability.** At 3am, how does on-call know this pipeline is broken? What would you measure?

You won't be asked to write code — just to explain your design choices and defend them.

---

## Bonus: LWC Bug Hunt (only if time permits)

If we wrap the design walkthrough early, we may pull up one more artifact together.

**Component:** `accountContactList` (`force-app/main/default/lwc/accountContactList`) — drop it on an Account record page.

The component lists Contacts for the current Account. Each row has a "Mark Primary" button that should update the "Primary contact:" line at the top of the card. **It doesn't.**

**Your task:** find the bug, describe the fix, and explain *why* it didn't work. No need to write the patch unless we have time and you want to.

Good luck.
