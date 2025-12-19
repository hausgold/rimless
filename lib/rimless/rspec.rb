# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'
require 'rimless'
require 'rimless/rspec/helpers'
require 'rimless/rspec/matchers'
require 'karafka/testing/rspec/helpers'

# This fake schema registry server uses Sinatra but the gem does not include
# this dependency as runtime, just as development. Therefore we added it.
require 'avro_turf/test/fake_confluent_schema_registry_server'

# Add a monkey patch to add propper Sinatra 4.x support
class FakeConfluentSchemaRegistryServer
  # Allow any host name on tests
  set :host_authorization, { permitted_hosts: [] }
end

# RSpec 1.x and 2.x compatibility
#
# @see http://bit.ly/2GbAYsU
raise 'No RSPEC_CONFIGURER is defined, webmock is missing?' \
  unless defined?(RSPEC_CONFIGURER)

RSPEC_CONFIGURER.configure do |config|
  config.include Rimless::RSpec::Helpers
  config.include Rimless::RSpec::Matchers
  config.include Karafka::Testing::RSpec::Helpers

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
  config.before(:each) do |example|
    # Get the Excon connection from the AvroTurf instance
    connection = Rimless.avro.instance_variable_get(:@registry)
                        .instance_variable_get(:@upstream)
                        .instance_variable_get(:@connection)
                        .instance_variable_get(:@data)
    # Enable WebMock on the already instantiated
    # Confluent Schema Registry Excon connection
    connection[:mock] = true
    # Grab all Confluent Schema Registry requests and send
    # them to the faked (inlined) Schema Registry
    stub_request(:any, %r{^http://#{connection[:hostname]}})
      .to_rack(FakeConfluentSchemaRegistryServer)
    # Clear any cached data
    FakeConfluentSchemaRegistryServer.clear

    # Do not interact with Apache Kafka itself on tests
    allow(WaterDrop::AsyncProducer).to receive(:call)
    allow(WaterDrop::SyncProducer).to receive(:call)

    # Reconfigure the Rimless AvroTurf instance
    Rimless.configure_avro_turf

    # When the example type is a Kafka consumer, we must initialize
    # the Karafka framework first.
    Rimless.consumer.initialize! if example.metadata[:type] == :consumer
  end
end
