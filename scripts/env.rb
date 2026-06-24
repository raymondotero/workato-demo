# frozen_string_literal: true

# Minimal zero-dependency .env loader so these scripts run with system Ruby,
# no bundler required. Mirrors how Workato connections read credentials from
# a secure store: nothing is hard-coded.
module Env
  def self.load\!(path = File.join(__dir__, "..", ".env"))
    return unless File.exist?(path)
    File.foreach(path) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")
      key, _, val = line.partition("=")
      key = key.strip
      val = val.strip.gsub(/\A["']|["']\z/, "")
      ENV[key] ||= val unless key.empty?
    end
  end

  def self.require\!(*keys)
    missing = keys.reject { |k| ENV[k] && \!ENV[k].empty? }
    return if missing.empty?
    warn "Missing required environment variables: #{missing.join(', ')}"
    warn "Copy .env.example to .env and fill in the values."
    exit 1
  end
end
