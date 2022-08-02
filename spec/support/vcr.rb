require "vcr"

def vcr_record_mode
  ENV["VCR_RECORD_MODE"]&.to_sym || :none
end

VCR.configure do |c|
  c.cassette_library_dir = "#{RSPEC_ROOT}/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.default_cassette_options = { record: vcr_record_mode }
  c.filter_sensitive_data("<HAPI_KEY>") { ENV.fetch("HUBSPOT_HAPI_KEY") }
  c.filter_sensitive_data("<PORTAL_ID>") { ENV.fetch("HUBSPOT_PORTAL_ID") }
  c.filter_sensitive_data("<ACCESS_TOKEN>") { ENV.fetch("HUBSPOT_ACCESS_TOKEN") }
end
