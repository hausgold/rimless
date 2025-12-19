# frozen_string_literal: true

module Rimless
  # The top-level dependencies helpers.
  module Dependencies
    extend ActiveSupport::Concern

    class_methods do
      # (Re)configure our gem dependencies. We take care of setting up
      # +WaterDrop+, our Apache Kafka driver and +AvroTurf+, our Confluent
      # Schema Registry driver.
      def configure_dependencies
        configure_waterdrop
        configure_avro_turf
      end

      # Set sensible defaults for the +WaterDrop+ gem.
      def configure_waterdrop
        # Skip WaterDrop configuration when no brokers/client id is available,
        # because it will raise. Its fine to have none available for situations
        # like Rails asset precompilations, etc. - on runtime the settings
        # should be available, otherwise the message producing just
        # fails/raise.
        return if Rimless.configuration.kafka_brokers.empty? \
          || Rimless.configuration.client_id.blank?

        WaterDrop.setup do |config|
          # Activate message delivery and use the default logger
          config.deliver = true
          config.logger = Rimless.logger
          # An optional identifier of a Kafka consumer (in a consumer group)
          # that is passed to a Kafka broker with every request. A logical
          # application name to be included in Kafka logs and monitoring
          # aggregates.
          config.client_id = Rimless.configuration.client_id
          # All the known brokers, at least one. The ruby-kafka driver will
          # discover the whole cluster structure once and when issues occur to
          # dynamically adjust scaling operations.
          config.kafka.seed_brokers = Rimless.configuration.kafka_brokers
          # All brokers MUST acknowledge a new message
          config.kafka.required_acks = -1
        end
      end

      # Set sensible defaults for the +AvroTurf+ gem and (re)compile the Apache
      # Avro schema templates (ERB), so the gem can handle them properly.
      def configure_avro_turf
        # No need to configure AvroTurf when no schema registry URL is
        # available. Its fine to skip this for scenarios where not the full
        # application configuration is available (eg. on Rails asset
        # precompilations, etc)
        return if Rimless.configuration.schema_registry_url.blank?

        # Setup a global available Apache Avro decoder/encoder with support for
        # the Confluent Schema Registry, but first create a helper instance
        Rimless.avro_utils = Rimless::AvroUtils.new
        # Compile our Avro schema templates to ready-to-consume Avro schemas
        Rimless.avro_utils.recompile_schemas
        # Register a global Avro messaging instance
        Rimless.avro = AvroTurf::Messaging.new(
          logger: Rimless.logger,
          namespace: Rimless.avro_utils.namespace,
          schemas_path: Rimless.avro_utils.output_path,
          registry_url: Rimless.configuration.schema_registry_url
        )
      end
    end
  end
end
