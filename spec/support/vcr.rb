# frozen_string_literal: true

require 'vcr'

unless ENV.fetch('VCR', 'true') == 'false'
  VCR.configure do |conf|
    conf.cassette_library_dir = 'spec/fixtures/cassettes'
    conf.hook_into :webmock
    conf.configure_rspec_metadata!
  end
end
