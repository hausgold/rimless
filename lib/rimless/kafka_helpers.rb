# frozen_string_literal: true

module Rimless
  # The top-level Apache Kafka helpers.
  module KafkaHelpers
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength because its an Active Support concern
    class_methods do
      # Generate a common topic name for Apache Kafka while taking care of
      # configured prefixes.
      #
      # @param name [String, Symbol] the topic name
      # @param app [String, Symbol] a different application name, by default
      #   the local app
      # @return [String] the complete topic name
      #
      # @example Name only
      #   Rimless.topic(:users)
      # @example Name with app
      #   Rimless.topic(:users, app: 'test-api')
      # @example Mix and match
      #   Rimless.topic(name: 'test', app: :fancy_app)
      #
      # rubocop:disable Metrics/AbcSize because of the usage flexibility
      def topic(*args)
        opts = args.last
        name = args.first if [String, Symbol].member?(args.first.class)

        if opts.is_a?(Hash)
          name = opts[:name] if opts.key?(:name)
          app = opts[:app] if opts.key?(:app)
        end

        name ||= nil
        app ||= Rimless.configuration.app_name

        raise ArgumentError, 'No name given' if name.nil?

        "#{Rimless.topic_prefix(app)}#{name}"
      end
      # rubocop:enable Metrics/AbcSize

      # Send a single message to Apache Kafka. The data is encoded according to
      # the given Apache Avro schema. The destination Kafka topic may be a
      # relative name, or a hash which is passed to the +.topic+ method to
      # manipulate the application details. The message is send is a
      # synchronous, blocking way.
      #
      # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
      # @param schema [String, Symbol] the Apache Avro schema to use
      # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
      #   Apache Kafka topic
      def sync_message(data:, schema:, topic:, **args)
        encoded = Rimless.avro.encode(data, schema_name: schema.to_s)
        sync_raw_message(data: encoded, topic: topic, **args)
      end
      alias_method :message, :sync_message

      # Send a single message to Apache Kafka. The data is encoded according to
      # the given Apache Avro schema. The destination Kafka topic may be a
      # relative name, or a hash which is passed to the +.topic+ method to
      # manipulate the application details. The message is send is an
      # asynchronous, non-blocking way.
      #
      # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
      # @param schema [String, Symbol] the Apache Avro schema to use
      # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
      #   Apache Kafka topic
      def async_message(data:, schema:, topic:, **args)
        encoded = Rimless.avro.encode(data, schema_name: schema.to_s)
        async_raw_message(data: encoded, topic: topic, **args)
      end

      # Send a single message to Apache Kafka. The data is not touched, so you
      # need to encode it yourself before you pass it in. The destination Kafka
      # topic may be a relative name, or a hash which is passed to the +.topic+
      # method to manipulate the application details. The message is send is a
      # synchronous, blocking way.
      #
      # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
      # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
      #   Apache Kafka topic
      def sync_raw_message(data:, topic:, **args)
        args = args.merge(topic: topic(topic))
        WaterDrop::SyncProducer.call(data, **args)
      end
      alias_method :raw_message, :sync_raw_message

      # Send a single message to Apache Kafka. The data is not touched, so you
      # need to encode it yourself before you pass it in. The destination Kafka
      # topic may be a relative name, or a hash which is passed to the +.topic+
      # method to manipulate the application details. The message is send is an
      # asynchronous, non-blocking way.
      #
      # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
      # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
      #   Apache Kafka topic
      def async_raw_message(data:, topic:, **args)
        args = args.merge(topic: topic(topic))
        WaterDrop::AsyncProducer.call(data, **args)
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
