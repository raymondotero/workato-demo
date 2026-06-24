#\!/usr/bin/env ruby
# frozen_string_literal: true
#
# Creates the LCI verification custom fields in Jira Cloud via the REST API.
# Optional: also creates the LCI project if JIRA_LEAD_ACCOUNT_ID is provided.
# Field creation is idempotent-ish: existing fields with the same name are skipped.
#
# Usage:
#   cp .env.example .env  and set JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
#   ruby scripts/setup_jira.rb

require "net/http"
require "json"
require "uri"
require "base64"
require_relative "env"

Env.load\!
Env.require\!("JIRA_BASE_URL", "JIRA_EMAIL", "JIRA_API_TOKEN")

BASE  = ENV["JIRA_BASE_URL"].sub(%r{/+\z}, "")
AUTH  = "Basic " + Base64.strict_encode64("#{ENV['JIRA_EMAIL']}:#{ENV['JIRA_API_TOKEN']}")

def api(method, path, payload = nil)
  uri = URI.parse("#{BASE}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  klass = { get: Net::HTTP::Get, post: Net::HTTP::Post }[method]
  req = klass.new(uri.request_uri)
  req["Authorization"] = AUTH
  req["Content-Type"]  = "application/json"
  req["Accept"]        = "application/json"
  req.body = payload.to_json if payload
  http.request(req)
end

# Jira Cloud custom field type keys
TEXT  = "com.atlassian.jira.plugin.system.customfieldtypes:textfield"
NUM   = "com.atlassian.jira.plugin.system.customfieldtypes:float"
PARA  = "com.atlassian.jira.plugin.system.customfieldtypes:textarea"

FIELDS = [
  ["Consignment ID", TEXT], ["Seller Name", TEXT], ["Seller Email", TEXT],
  ["Brand", TEXT], ["Model", TEXT], ["Estimated Value", NUM],
  ["Authentication Result", TEXT], ["Condition Grade", TEXT],
  ["Verifier Confidence", NUM], ["Recommended Buy Price", NUM],
  ["Selling Price Min", NUM], ["Selling Price Max", NUM],
  ["Escalation Reason", PARA]
]

puts "Reading existing fields ..."
existing_res = api(:get, "/rest/api/3/field")
existing = existing_res.code == "200" ? JSON.parse(existing_res.body).map { |f| f["name"] } : []

FIELDS.each do |name, type|
  if existing.include?(name)
    puts "  skip (exists): #{name}"
    next
  end
  res = api(:post, "/rest/api/3/field", { "name" => name, "type" => type })
  if %w[200 201].include?(res.code)
    puts "  created: #{name}"
  else
    puts "  FAILED (#{res.code}): #{name} -> #{res.body}"
  end
end

if ENV["JIRA_LEAD_ACCOUNT_ID"] && \!ENV["JIRA_LEAD_ACCOUNT_ID"].empty?
  puts "Creating project LCI (Verification) ..."
  proj = {
    "key" => "LCI", "name" => "Verification",
    "projectTypeKey" => "software",
    "projectTemplateKey" => "com.pyxis.greenhopper.jira:gh-simplified-kanban-classic",
    "leadAccountId" => ENV["JIRA_LEAD_ACCOUNT_ID"]
  }
  res = api(:post, "/rest/api/3/project", proj)
  puts %w[200 201].include?(res.code) ? "  project created" : "  project create (#{res.code}): #{res.body}"
else
  puts "JIRA_LEAD_ACCOUNT_ID not set; create the LCI project (key LCI, Task issue type) in the UI."
end

puts "Done. Add the new fields to the LCI Task screen in Project settings > Screens."
