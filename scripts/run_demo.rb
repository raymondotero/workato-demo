#\!/usr/bin/env ruby
# frozen_string_literal: true
#
# LCI demo runner. Fires the four mandatory payloads at the Workato webhooks
# in the required execution order and prints the response plus a manual
# verification checklist. Written in Ruby to match Workato's SDK / formula style.
#
# Usage:
#   1. cp .env.example .env  and set RECIPE_1_WEBHOOK_URL and RECIPE_2_WEBHOOK_URL
#   2. ruby scripts/run_demo.rb            # runs the whole sequence
#   ruby scripts/run_demo.rb amelia        # just Amelia (intake + verification)
#   ruby scripts/run_demo.rb daniel        # just Daniel (intake + escalation)

require "net/http"
require "json"
require "uri"
require_relative "env"

Env.load\!
Env.require\!("RECIPE_1_WEBHOOK_URL", "RECIPE_2_WEBHOOK_URL")

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

target = (ARGV[0] || "all").downcase
r1 = ENV["RECIPE_1_WEBHOOK_URL"]
r2 = ENV["RECIPE_2_WEBHOOK_URL"]

if %w[all amelia].include?(target)
  step "1) Amelia intake  (standard path setup)"
  post(r1, "amelia_intake.json")
  checklist(
    "Salesforce Contact Amelia Hart created",
    "Consignment Item LCI-AMELIA-CHANEL-001, Status = Verification Assigned, Jira Issue Key set",
    "Jira task created for the Chanel Classic Flap",
    "Slack message in #lci-verification"
  )
  sleep 2
  step "2) Amelia verification  (Pass, 0.94, $6,200 -> CLEANING QUEUE)"
  post(r2, "amelia_verification.json")
  checklist(
    "Salesforce Status = Cleaning Queue, Authentication Result = Pass, Condition Grade = A",
    "AI Status Summary populated, Approval Status = Not Required",
    "Jira fields updated and verification comment added",
    "Slack message in #lci-customer-support"
  )
end

if %w[all daniel].include?(target)
  sleep 2
  step "3) Daniel intake  (escalation path setup)"
  post(r1, "daniel_intake.json")
  checklist(
    "Salesforce Contact Daniel Moreau created",
    "Consignment Item LCI-DANIEL-BIRKIN-001, Status = Verification Assigned, Jira Issue Key set",
    "Jira task created for the Hermes Birkin 30",
    "Slack message in #lci-verification"
  )
  sleep 2
  step "4) Daniel verification  (Needs Review, 0.62, $18,000 -> ESCALATION)"
  post(r2, "daniel_verification.json")
  checklist(
    "Salesforce Status = Escalation Pending, Approval Status = Pending, Escalation Reason populated",
    "AI Status Summary populated",
    "Slack approval message with two buttons in #lci-senior-auth"
  )
  puts ""
  puts "  NEXT: click 'Approve Senior Review' in #lci-senior-auth, then verify:"
  checklist(
    "Salesforce Status = Senior Review Approved, Approval Status = Approved, Approved By / Approved At set",
    "Jira senior approval comment added",
    "Slack confirmation in #lci-customer-support"
  )
end

puts ""
puts "Done. Any recipe failure should post to #lci-automation-alerts."
