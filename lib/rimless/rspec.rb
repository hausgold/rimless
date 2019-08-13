# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'
require 'avro_turf/test/fake_confluent_schema_registry_server'
require 'rimless'
require 'rimless/rspec/helpers'
require 'rimless/rspec/matchers'

# RSpec 1.x and 2.x compatibility
#
# @see http://bit.ly/2GbAYsU
raise 'No RSPEC_CONFIGURER is defined, webmock is missing?' \
  unless defined?(RSPEC_CONFIGURER)

RSPEC_CONFIGURER.configure do |config|
  config.include Rimless::RSpec::Helpers
  config.include Rimless::RSpec::Matchers

  # Stub all Confluent Schema Registry requests and handle them gracefully with
  # the help of the faked (inlined) Schema Registry server. This allows us to
  # perform the actual Apache Avro message encoding/decoding without the need
  # to have a Schema Registry up and running.
  config.before do
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

    # This allows parallel test execution without race conditions on the
    # compiled Apache Avro schemas.  So when each test have its own compiled
    # schema repository it cannot conflict while refreshing it.
    unless ENV['TEST_ENV_NUMBER'].nil?
      Rimless.configure do |conf|
        conf.compiled_avro_schema_path = conf.compiled_avro_schema_path.join(
          "test-worker-#{ENV['TEST_ENV_NUMBER']}"
        )
      end
    end

    # Reconfigure the Rimless AvroTurf instance
    Rimless.configure_avro_turf
  end
end
