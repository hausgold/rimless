# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'
require 'rimless'
require 'rimless/rspec/helpers'
require 'rimless/rspec/matchers'
require 'avro_turf/test/fake_confluent_schema_registry_server'
require 'karafka/testing/rspec/helpers'

# RSpec 1.x and 2.x compatibility
#
# @see http://bit.ly/2GbAYsU
raise 'No RSPEC_CONFIGURER is defined, webmock is missing?' \
  unless defined?(RSPEC_CONFIGURER)

RSPEC_CONFIGURER.configure do |config|
  config.include Rimless::RSpec::Helpers
  config.include Rimless::RSpec::Matchers

  # Load the Karafka testing helpers when we're running in an actual end-user
  # application, not within our own test suite as we do not provide a
  # `karafka.rb` boot entry
  config.include Karafka::Testing::RSpec::Helpers \
    unless Karafka::App.initializing?

  # Set the custom +consumer+ type for consumer spec files
  config.define_derived_metadata(file_path: %r{/spec/consumers/}) do |meta|
    meta[:type] = :consumer
  end

  # Take care of the initial test configuration.
  config.before(:suite) do
    # This allows parallel test execution without race conditions on the
    # compiled Apache Avro schemas.  So when each test have its own compiled
    # schema repository it cannot conflict while refreshing it.
    unless ENV['TEST_ENV_NUMBER'].nil?
      Rimless.configure do |conf|
        num = ENV.fetch('TEST_ENV_NUMBER', nil)
        num = '1' if num.empty?

        conf.compiled_avro_schema_path =
          conf.compiled_avro_schema_path.join("test-worker-#{num}")
      end
    end
  end

  # Stub all Confluent Schema Registry requests and handle them gracefully with
  # the help of the faked (inlined) Schema Registry server. This allows us to
  # perform the actual Apache Avro message encoding/decoding without the need
  # to have a Schema Registry up and running.
  config.before(:each) do
    # Intercept all Confluent Schema Registry requests and send
    # them to the faked (inlined) Schema Registry
    stub_request(:any, /^#{Rimless.configuration.schema_registry_url}/)
      .to_rack(FakeConfluentSchemaRegistryServer)
    # Clear any cached data
    FakeConfluentSchemaRegistryServer.clear

    # Do not interact with Apache Kafka itself on tests
    allow(Rimless.producer).to receive(:produce_sync)
    allow(Rimless.producer).to receive(:produce_async)

    # Reconfigure the Rimless AvroTurf instance
    Rimless.configure_avro
  end
end
