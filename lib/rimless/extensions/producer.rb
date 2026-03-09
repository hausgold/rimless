# frozen_string_literal: true

module Rimless
  module Extensions
    # The top-level Apache Kafka message producer integration.
    module Producer
      extend ActiveSupport::Concern

      class_methods do
        # A shared +WaterDrop::Producer+ instance
        mattr_accessor :producer

        # Send a single message to Apache Kafka. The data is encoded according
        # to the given Apache Avro schema. The destination Kafka topic may be a
        # relative name, or a hash which is passed to the +.topic+ method to
        # manipulate the application details. The message is send is a
        # synchronous, blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param schema [String, Symbol] the Apache Avro schema to use
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def sync_message(data:, schema:, topic:, **args)
          encoded = Rimless.encode(data, schema: schema)
          sync_raw_message(data: encoded, topic: topic, **args)
        end
        alias_method :message, :sync_message

        # Send a single message to Apache Kafka. The data is encoded according
        # to the given Apache Avro schema. The destination Kafka topic may be a
        # relative name, or a hash which is passed to the +.topic+ method to
        # manipulate the application details. The message is send is an
        # asynchronous, non-blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param schema [String, Symbol] the Apache Avro schema to use
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def async_message(data:, schema:, topic:, **args)
          encoded = Rimless.encode(data, schema: schema)
          async_raw_message(data: encoded, topic: topic, **args)
        end

        # Send a single message to Apache Kafka. The data is not touched, so
        # you need to encode it yourself before you pass it in. The destination
        # Kafka topic may be a relative name, or a hash which is passed to the
        # +.topic+ method to manipulate the application details. The message is
        # send is a synchronous, blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def sync_raw_message(data:, topic:, **args)
          args = args.merge(topic: topic(topic), payload: data)
          producer.produce_sync(**args)
        end
        alias_method :raw_message, :sync_raw_message

        # Send a single message to Apache Kafka. The data is not touched, so
        # you need to encode it yourself before you pass it in. The destination
        # Kafka topic may be a relative name, or a hash which is passed to the
        # +.topic+ method to manipulate the application details. The message is
        # send is an asynchronous, non-blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def async_raw_message(data:, topic:, **args)
          args = args.merge(topic: topic(topic), payload: data)
          producer.produce_async(**args)
        end
      end
    end
  end
end
