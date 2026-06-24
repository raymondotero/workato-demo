# workato-demo

Live sandbox demo for the Workato Chief Architect panel: **LCI Seller Experience Modernization**.

This repo scaffolds the parts that are faster as code. The Workato recipes are built by hand in the Workato canvas (there is no clean repo deploy path for recipes). Scripts are in Ruby to match Workato's SDK and formula style, with a cURL fallback.

## What this proves

An event-driven, governed-AI seller pipeline for Luxury Consignment Inc.: intake, then a Salesforce status record, a Jira verification task, a Slack notification, a governed senior-authenticator approval, and an internal AI status summary. Amelia (Chanel, Pass, high confidence) runs the clean path to Cleaning Queue. Daniel (Hermes Birkin, Needs Review, low confidence, high value) triggers a governed escalation with no autonomous decision and no seller contact.

**Mandatory scope:** Workato, Salesforce, Jira, Slack, AI by Workato. This is the demo core and the gradeable acceptance criteria.

**Buy-side extension (optional, due diligence):** the Workato instructions also ask you to provision a Shopify sandbox. The sell side is intentionally the demo core because LCI's own ask is "we want to start here." To show full coverage, this repo also includes a lightweight Shopify buy-side proof: a new order flows into a unified buyer profile in Salesforce, with a governed, internal-only AI personalization suggestion. It uses the same event-driven, human-governed pattern, framed as Phase 2. Build it only after the sell-side demo is solid.

## Repo layout

```
force-app/main/default/objects/Consignment_Item__c/   Sell-side object + 27 fields
force-app/main/default/objects/Buyer_Purchase__c/     Buy-side object + 13 fields (extension)
force-app/main/default/tabs/                           Custom tabs
manifest/package.xml                                   Deploy manifest
scripts/run_demo.rb        Ruby demo runner (sell-side, plus optional buyer step)
scripts/setup_jira.rb      Ruby Jira field/project setup via REST
scripts/run-demo.sh        cURL fallback
scripts/payloads/*.json    Test payloads (4 sell-side, 1 buy-side)
.env.example               Copy to .env and fill in
```

## Build order

1. Deploy Salesforce metadata (both objects deploy together)
2. Set up Jira (script or UI)
3. Create the Slack channels and the Workato Slack app
4. Create the Workato connections
5. Build Recipe 1, then 2, then 3 in Workato (sell side)
6. Run the sell-side demo and confirm the acceptance criteria
7. Optional: build Recipe 4 (Shopify) and run the buyer step
8. Rehearse the talk track

Full step-by-step with all recipe field mappings lives in the Town runbook doc.

## 1. Deploy the Salesforce data model

Requires the Salesforce CLI (`sf`).

```bash
sf org login web --alias lci
sf project deploy start --source-dir force-app --target-org lci
```

This creates `Consignment_Item__c` (27 fields), `Buyer_Purchase__c` (13 fields, linked to Contact), and both tabs in one deploy. To deploy only the mandatory sell side, deploy the `Consignment_Item__c` object folder by itself.

## 2. Set up Jira

```bash
cp .env.example .env   # fill in JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
ruby scripts/setup_jira.rb
```

Creates the 13 verification custom fields. Set `JIRA_LEAD_ACCOUNT_ID` to also auto-create the LCI project, or create the project (key `LCI`, Task issue type) in the UI. After creation, add the fields to the LCI Task screen under Project settings > Screens.

## 3. Slack

Sell-side channels: `#lci-verification`, `#lci-senior-auth`, `#lci-customer-support`, `#lci-automation-alerts`. Buy-side extension adds `#lci-buyer-activity`. Install the Workato Slack connection and confirm interactive components are enabled (Recipe 3 listens for Slack button clicks).

## 4. Workato connections

Salesforce, Jira, Slack, AI by Workato, Workato Webhooks. For the buy-side extension, also add the Shopify connection.

## 5. Build the sell-side recipes

- **Recipe 1, LCI - Seller Intake to Verification:** webhook `lci_seller_intake`. Upsert Contact by email, create `Consignment_Item__c`, create the Jira task, write the Jira key back to Salesforce, set Status = Verification Assigned, post to `#lci-verification`.
- **Recipe 2, LCI - Verification Result to Seller Status:** webhook `lci_verification_result`. Escalate if authentication_result is Needs Review or Fail, OR verifier_confidence < 0.85, OR Estimated_Value__c >= 15000. Standard path goes to Cleaning Queue and posts to `#lci-customer-support`. Escalation sets Escalation Pending and posts a two-button approval to `#lci-senior-auth`. AI by Workato writes an internal, evidence-based summary only (no pricing or authentication decisions, no seller-facing draft).
- **Recipe 3, LCI - Senior Authenticator Slack Approval:** Slack button-click trigger. Parse `decision|consignment_id`. Approve sets Senior Review Approved and comments on Jira; Reject sets Rejected. Both notify `#lci-customer-support`.

Wrap each recipe body in a Handle errors block that posts to `#lci-automation-alerts`.

## 6. Optional: build the buy-side recipe (Shopify)

- **Recipe 4, LCI - Buyer Order to Unified Profile:** trigger on the Shopify New paid order event (for the live demo you can use a Workato webhook `lci_buyer_order` for a deterministic run; the included payload fits both). Upsert the Salesforce Contact by buyer email, create a `Buyer_Purchase__c` linked to that Contact, run AI by Workato for an internal, governed next-best-offer suggestion (no autonomous discounting, no buyer-facing message), then post to `#lci-buyer-activity`. Wrap in Handle errors to `#lci-automation-alerts`.

This closes LCI's stated buy-side gap (no unified view of browsing, purchase history, and marketing) using the same governed pattern as the sell side.

## 7. Run the demo

```bash
cp .env.example .env    # set RECIPE_1_WEBHOOK_URL, RECIPE_2_WEBHOOK_URL (and RECIPE_4 for buyer)
ruby scripts/run_demo.rb           # full sell-side sequence with a checklist
ruby scripts/run_demo.rb amelia    # standard path only
ruby scripts/run_demo.rb daniel    # escalation path only
ruby scripts/run_demo.rb buyer     # optional buy-side extension
# or, no Ruby:  bash scripts/run-demo.sh
```

After Daniel's verification, click Approve Senior Review in `#lci-senior-auth` to close the loop.

## Acceptance criteria (mandatory sell side, all must be true)

Intake creates/updates a Salesforce Contact, creates a Consignment Item, creates a Jira task, posts to `#lci-verification`. Standard verification updates Jira, sets Cleaning Queue, writes the AI summary, posts to `#lci-customer-support`. Escalation updates Jira, sets Escalation Pending, posts approval to `#lci-senior-auth`. Slack approval sets Senior Review Approved, comments on Jira, notifies `#lci-customer-support`. Any failure posts to `#lci-automation-alerts`.
