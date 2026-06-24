# workato-demo

Live sandbox demo for the Workato Chief Architect panel: **LCI Seller Experience Modernization**.

This repo scaffolds the parts that are faster as code. The three Workato recipes are built by hand in the Workato canvas (there is no clean repo deploy path for recipes). Scripts are in Ruby to match Workato's SDK and formula style, with a cURL fallback.

## What this proves

An event-driven, governed-AI seller pipeline for Luxury Consignment Inc.: intake, then a Salesforce status record, a Jira verification task, a Slack notification, a governed senior-authenticator approval, and an internal AI status summary. Amelia (Chanel, Pass, high confidence) runs the clean path to Cleaning Queue. Daniel (Hermes Birkin, Needs Review, low confidence, high value) triggers a governed escalation with no autonomous decision and no seller contact.

In scope: Workato, Salesforce, Jira, Slack, AI by Workato. Out of scope: Shopify, Stripe, carriers, buyer personalization, loyalty, data warehouse.

## Repo layout

```
force-app/main/default/objects/Consignment_Item__c/   Salesforce object + 27 fields
force-app/main/default/tabs/                           Custom tab
manifest/package.xml                                   Deploy manifest
scripts/run_demo.rb        Ruby demo runner (fires the 4 payloads in order)
scripts/setup_jira.rb      Ruby Jira field/project setup via REST
scripts/run-demo.sh        cURL fallback
scripts/payloads/*.json    The 4 mandatory test payloads
.env.example               Copy to .env and fill in
```

## Build order (do this in sequence)

1. Deploy Salesforce metadata (below)
2. Set up Jira (script or UI)
3. Create the 4 Slack channels and the Workato Slack app
4. Create the 5 Workato connections
5. Build Recipe 1, then 2, then 3 in Workato
6. Run the demo script
7. Rehearse the talk track

Full step-by-step with the recipe field mappings lives in the Town runbook doc.

## 1. Deploy the Salesforce data model

Requires the Salesforce CLI (`sf`).

```bash
sf org login web --alias lci
sf project deploy start --source-dir force-app --target-org lci
```

This creates the `Consignment_Item__c` object, all 27 fields, and the tab in one shot. Open the object in Setup to confirm.

## 2. Set up Jira

```bash
cp .env.example .env   # fill in JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
ruby scripts/setup_jira.rb
```

Creates the 13 verification custom fields. Set `JIRA_LEAD_ACCOUNT_ID` to also auto-create the LCI project, or create the project (key `LCI`, Task issue type) in the UI. After creation, add the fields to the LCI Task screen under Project settings > Screens.

## 3. Slack

Create channels: `#lci-verification`, `#lci-senior-auth`, `#lci-customer-support`, `#lci-automation-alerts`. Install the Workato Slack connection and confirm interactive components are enabled (Recipe 3 listens for Slack button clicks).

## 4. Workato connections

Salesforce, Jira, Slack, AI by Workato, Workato Webhooks.

## 5. Build the three recipes

- **Recipe 1, LCI - Seller Intake to Verification:** webhook `lci_seller_intake`. Upsert Contact by email, create `Consignment_Item__c`, create the Jira task, write the Jira key back to Salesforce, set Status = Verification Assigned, post to `#lci-verification`.
- **Recipe 2, LCI - Verification Result to Seller Status:** webhook `lci_verification_result`. Escalate if authentication_result is Needs Review or Fail, OR verifier_confidence < 0.85, OR Estimated_Value__c >= 15000. Standard path goes to Cleaning Queue and posts to `#lci-customer-support`. Escalation path sets Escalation Pending and posts a two-button approval to `#lci-senior-auth`. AI by Workato writes an internal, evidence-based summary only (no pricing or authentication decisions, no seller-facing draft).
- **Recipe 3, LCI - Senior Authenticator Slack Approval:** Slack button-click trigger. Parse `decision|consignment_id`. Approve sets Senior Review Approved and comments on Jira; Reject sets Rejected. Both notify `#lci-customer-support`.

Wrap each recipe's body in a Handle errors block that posts to `#lci-automation-alerts`.

## 6. Run the demo

```bash
cp .env.example .env    # set RECIPE_1_WEBHOOK_URL and RECIPE_2_WEBHOOK_URL
ruby scripts/run_demo.rb           # full sequence with a verification checklist
ruby scripts/run_demo.rb amelia    # standard path only
ruby scripts/run_demo.rb daniel    # escalation path only
# or, no Ruby:  bash scripts/run-demo.sh
```

After Daniel's verification, click Approve Senior Review in `#lci-senior-auth` to close the loop.

## Acceptance criteria (all must be true)

Intake creates/updates a Salesforce Contact, creates a Consignment Item, creates a Jira task, posts to `#lci-verification`. Standard verification updates Jira, sets Cleaning Queue, writes the AI summary, posts to `#lci-customer-support`. Escalation updates Jira, sets Escalation Pending, posts approval to `#lci-senior-auth`. Slack approval sets Senior Review Approved, comments on Jira, notifies `#lci-customer-support`. Any failure posts to `#lci-automation-alerts`.
