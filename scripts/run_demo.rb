#!/usr/bin/env ruby
# frozen_string_literal: true
#
# LCI demo runner (final architecture, June 26 2026).
#
# Matches the Demo Day Run Sheet exactly:
#   - Verification is EVENT-DRIVEN off the Salesforce record (no verification cURL).
#     You fire ONE intake per item and routing happens automatically.
#   - Senior approval runs through the LCI Senior Decision webhook (lci_decision),
#     NOT Slack buttons.
#   - Optional Phase 2 bonus: cleaning -> Ready for Listing (lci_cleaning_complete).
#
# Each runbook command is its own selectable target so you can fire them
# one at a time, live, in order.
#
# Usage:
#   cp .env.example .env   and set INTAKE_WEBHOOK_URL and DECISION_WEBHOOK_URL
#   ruby scripts/run_demo.rb amelia        # 1)  Amelia intake (clean auto-verify)
#   ruby scripts/run_demo.rb cleaning      # 1b) Amelia cleaning -> Ready for Listing (optional bonus)
#   ruby scripts/run_demo.rb daniel        # 2)  Daniel intake (governed escalation)
#   ruby scripts/run_demo.rb approve       # 3)  Submit senior decision: approve LCI-2001
#   ruby scripts/run_demo.rb reject-intake # 4a) Fresh Daniel intake LCI-2002 (reject setup)
#   ruby scripts/run_demo.rb reject        # 4b) Submit senior decision: reject LCI-2002
#   ruby scripts/run_demo.rb all           # full sell-side sequence in order
#
# "all" runs: amelia -> cleaning(if built) -> daniel -> approve.
# The reject path is intentionally manual so you control it live.

require "net/http"
require "json"
require "uri"
require_relative "env"

Env.load!
Env.require!("INTAKE_WEBHOOK_URL", "DECISION_WEBHOOK_URL")

PAYLOADS = File.join(__dir__, "payloads")

def post(url, file)
  uri = URI.parse(url)
  body = File.read(File.join(PAYLOADS, file))
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  req = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
  req.body = body
  res = http.request(req)
  puts "  -> HTTP #{res.code}"
  begin
    puts "  -> #{JSON.pretty_generate(JSON.parse(res.body))}".gsub("\n", "\n  ")
  rescue StandardError
    puts "  -> #{res.body}"
  end
  res
end

def step(title)
  puts ""
  puts "=" * 72
  puts title
  puts "=" * 72
end

def checklist(*items)
  puts "  Verify:"
  items.each { |i| puts "    [ ] #{i}" }
end

target  = (ARGV[0] || "all").downcase
intake  = ENV["INTAKE_WEBHOOK_URL"]
decide  = ENV["DECISION_WEBHOOK_URL"]
clean   = ENV["CLEANING_WEBHOOK_URL"]

def amelia(intake)
  step "1) Amelia intake  (clean auto-verify path, LCI-1001)"
  post(intake, "amelia_intake.json")
  checklist(
    "Salesforce Consignment Item LCI-1001 created and auto-cleared (no escalation)",
    "AI scored high confidence (> 79); routed straight through",
    "Slack message in #lci-customer-support",
    "No human touch, no Jira review ticket"
  )
end

def cleaning(clean)
  if clean.nil? || clean.empty?
    puts ""
    puts "(Cleaning step skipped: set CLEANING_WEBHOOK_URL in .env once the bonus recipe is built and started.)"
    return
  end
  step "1b) Amelia cleaning complete -> Ready for Listing  (optional Phase 2 bonus, LCI-1001)"
  post(clean, "amelia_cleaning_complete.json")
  checklist(
    "Salesforce LCI-1001 Current Status = Ready for Listing",
    "Evidence Log shows the appended cleaning entry",
    "Slack 'ready for listing' message in #lci-customer-support"
  )
  puts ""
  puts "  SAY THE HANDOFF LINE: 'This is where Shopify would connect in a later phase...'"
end

def daniel(intake)
  step "2) Daniel intake  (governed escalation, LCI-2001)"
  post(intake, "daniel_intake.json")
  checklist(
    "AI scores ~65%; item HOLDS at Escalation Pending in Salesforce",
    "Jira review ticket created",
    "Clean governance post (NO buttons) in #lci-senior-auth with confidence, reason, Jira key"
  )
  puts ""
  puts "  Wait 10-15 seconds for the escalation to post before submitting the decision."
end

def approve(decide)
  step "3) Senior decision: APPROVE  (LCI-2001)"
  post(decide, "decision_approve.json")
  checklist(
    "Salesforce LCI-2001 Status = Senior Review Approved",
    "#lci-customer-support gets the 'approved after senior review' message",
    "#lci-senior-auth gets 'Approved by Raymond Otero. Loop closed.'"
  )
end

def reject_intake(intake)
  step "4a) Fresh Daniel intake  (reject-path setup, LCI-2002)"
  post(intake, "daniel_intake_reject.json")
  checklist(
    "Salesforce Consignment Item LCI-2002 created, escalates to #lci-senior-auth"
  )
  puts ""
  puts "  Wait for the escalation to post, then run: ruby scripts/run_demo.rb reject"
end

def reject(decide)
  step "4b) Senior decision: REJECT  (LCI-2002)"
  post(decide, "decision_reject.json")
  checklist(
    "Salesforce LCI-2002 Status = Rejected",
    "Both channels post the rejection with a follow-up flag"
  )
end

case target
when "amelia"        then amelia(intake)
when "cleaning"      then cleaning(clean)
when "daniel"        then daniel(intake)
when "approve"       then approve(decide)
when "reject-intake" then reject_intake(intake)
when "reject"        then reject(decide)
when "all"
  amelia(intake)
  sleep 2
  cleaning(clean)
  sleep 2
  daniel(intake)
  puts ""
  puts "  Pausing 15s so the escalation can post before the decision..."
  sleep 15
  approve(decide)
  puts ""
  puts "  (Reject path is manual: run 'reject-intake' then 'reject' if you want to show it.)"
else
  warn "Unknown target '#{target}'."
  warn "Valid: amelia | cleaning | daniel | approve | reject-intake | reject | all"
  exit 1
end

puts ""
puts "Done. The decision endpoint is deterministic, so you can safely re-fire the same"
puts "command on the same ID if a live post lags. Any recipe failure posts to #lci-automation-alerts."
