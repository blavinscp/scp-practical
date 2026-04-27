# SCP Developer Practical Exam

Welcome! This is a short, hands-on exercise for Salesforce developer candidates. You should be able to complete it in **under an hour**. Talk through your thinking as you work — we care more about *how* you reason about the problems than whether you fix every line.

## Setup

The interviewer has already created a scratch org for you. To confirm you're connected:

```bash
sf org display
```

If you need to spin up your own:

```bash
./scripts/setup.sh practical-exam
```

## Exercises

### 1. Apex Trigger Refactor
**Files:** `force-app/main/default/triggers/ContactTrigger.trigger`

The `ContactTrigger` is supposed to maintain a `Contact_Count__c` rollup on the Account whenever Contacts are inserted. It works for one record at a time but breaks under realistic load.

Try to seed the org with sample data:

```bash
sf apex run --file scripts/apex/seed.apex
```

**Your task:**
1. Explain what's wrong.
2. Refactor the trigger so the seed script runs successfully.
3. Mention any cases the trigger doesn't currently cover.

### 2. Flow Refactor
**Flow:** `Account_Stamp_Region` (on Account)

This Record-Triggered Flow stamps `Account.Region__c` based on `BillingState`. It works, but it's not following best practices for performance.

**Your task:** Open the flow in Setup, identify what's inefficient, and refactor it.

### 3. LWC Bug
**Component:** `accountContactList` (drop it on an Account record page)

The component lists Contacts for the current Account. Each row has a "Mark Primary" button that should update the "Primary contact:" line at the top of the card. **It doesn't.**

**Your task:** Find the bug and fix it. Bonus: explain *why* it didn't work.

## Tips
- Browser devtools, debug logs, and the Setup UI are all fair game.
- If you get stuck, talk through what you're seeing — we may nudge you.
