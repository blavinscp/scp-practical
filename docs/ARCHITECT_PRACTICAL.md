# SCP Technical Architect Practical Exam

Welcome. This is a **~1-hour exercise** combining a short hands-on code fix with an architecture discussion. We're looking for how you think about integration architecture on the Salesforce platform: the patterns you pick, the risks you anticipate, and how clearly you can communicate your reasoning under time pressure.

| Time | Activity |
|------|----------|
| 0–20 min | **Code review & fix** — review the 2 artifacts in [Part 1](#part-1-code-review--fix-20-min); refactor the trigger |
| 20–55 min | **Integration walkthrough** — walk through the diagram in [Part 2](#part-2-integration-walkthrough-35-min) and discuss tradeoffs at each interaction |
| 55–60 min | **Bonus / wrap-up** — optional LWC bug hunt if time permits |

---

## Part 1: Code Review & Fix (~20 min)

Review two artifacts in the repo. Each one contains at least one anti-pattern or bug. For each artifact, be ready to:

- **Name the issue(s)** — what's wrong?
- **Explain the risk** — what breaks at scale, in production, or under load?
- **Describe the fix** — what would you change and why?

| # | Artifact | Location | What it does |
|---|----------|----------|-------------|
| 1 | **ContactTrigger** | `force-app/main/default/triggers/ContactTrigger.trigger` | An Apex trigger on Contact that maintains a `Contact_Count__c` rollup on Account. |
| 2 | **Account_Stamp_Region flow** | `force-app/main/default/flows/Account_Stamp_Region.flow-meta.xml` | A record-triggered flow on Account that stamps a `Region__c` field based on `BillingState`. It maps CA/OR/WA → "West", NY/NJ → "East", everything else → "Other". |

### Hands-on: refactor the ContactTrigger

The interviewer has already created a scratch org for you. Confirm you're connected:

```bash
sf org display
```

If you need to spin up your own:

```bash
./scripts/setup.sh practical-exam
```

Try to seed the org with sample data — it will fail against the current trigger:

```bash
sf apex run --file scripts/apex/seed.apex
```

**Your task:**

1. Explain what's wrong with `ContactTrigger`.
2. Refactor the trigger so the seed script runs successfully.
3. Call out any cases the trigger still doesn't cover (update, delete, reparenting, undelete, etc.) — you don't have to implement them, but be ready to discuss.

For the **flow**, you don't need to change anything — just be ready to name the issue and the fix.

---

## Part 2: Integration Walkthrough (~35 min)

You will **not** be asked to draw anything. The diagram below is your starting point. Walk the interviewer through it end-to-end, and at each interaction (intake → NPPES, Provider → PSV submit, PSV callback, platform event fan-out) be ready to discuss the **decisions, tradeoffs, and considerations** an architect would weigh.

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

### How the walkthrough will go

The interviewer will drive. Expect to talk through each leg of the diagram and the cross-cutting concerns below. There are no single right answers — we're listening for the tradeoffs you weigh.

**At each interaction, be prepared to discuss:**

- **Intake → NPPES (sync).** Where does the callout live (LWC + Apex, Flow + HTTP action, External Service)? Named Credential vs. anonymous? Timeout and circuit-breaker behavior. What does the clerk see when NPPES is slow or down — block, degrade, or queue? How do you avoid burning Apex CPU/heap on a clerk-facing screen?
- **Provider → PSV (async submit).** Sync HTTP callout vs. Queueable vs. Platform Event-driven submit. How do you capture and persist `Verification_Job_Id__c` atomically with the status change? What happens if the submit succeeds but the DML to stamp the job id fails?
- **PSV → Provider (callback).** Webhook into a public Site/Experience guest user vs. authenticated REST vs. polling. How do you authenticate the callback (HMAC, mTLS, signed JWT)? Where do retries originate — PSV's retry policy or yours? How do you keep callback processing fast (Apex REST → enqueue → return 200)?
- **Provider → Platform Event (fan-out).** Why `Provider_Onboarded__e` and not a Change Data Capture event or an outbound message? What's on the payload and why *only* those fields? High-volume vs. standard-volume event? Replay strategy for consumers.

**Cross-cutting concerns:**

- **Error handling & retry.** What happens when NPPES is down? When PSV takes two days? When a callback never arrives? Where do you put the dead-letter queue?
- **Idempotency.** What if the same NPI is submitted twice in the same minute? What if a PSV callback arrives three times? How does `NPI__c` as External ID help — and where does it not?
- **State machine.** Does `Status__c` (`Draft` → `Intake_Complete` → `Verification_Pending` → `Verified` / `Rejected`) capture every transition? What breaks if someone resubmits during verification? Where do you enforce the transitions — validation rule, trigger, flow?
- **PHI / security.** Which fields are sensitive? Where does sensitive data end up in logs, debug logs, or event payloads? How do you prove field-level access at audit time? Named Credentials + Shield considerations?
- **Observability.** At 3am, how does on-call know this pipeline is broken? What do you measure — submit rate, callback latency, verification age, event publish failures? Platform Event monitoring, Event Monitoring, custom log object?

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

## Bonus: LWC Bug Hunt (only if time permits)

If we wrap the design walkthrough early, we may pull up one more artifact together.

**Component:** `accountContactList` (`force-app/main/default/lwc/accountContactList`) — drop it on an Account record page.

The component lists Contacts for the current Account. Each row has a "Mark Primary" button that should update the "Primary contact:" line at the top of the card. **It doesn't.**

**Your task:** find the bug, describe the fix, and explain *why* it didn't work. No need to write the patch unless we have time and you want to.

Good luck.
