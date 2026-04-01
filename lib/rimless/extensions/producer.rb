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
        # manipulate the application details. The message is sent is a
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
        # manipulate the application details. The message is sent is an
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

        # Send a single message to Apache Kafka. The data is not transformed, so
        # you need to encode it yourself before you pass it in. The destination
        # Kafka topic may be a relative name, or a hash which is passed to the
        # +.topic+ method to manipulate the application details. The message is
        # sent is a synchronous, blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param headers [Hash{String => String, Array<String>}, nil] the
        #   message headers to send
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def sync_raw_message(data:, topic:, headers: nil, **args)
          args = args.merge(topic: topic(topic), payload: data)

          # A compatibility helper for headers, as WaterDrop is now more strict
          if headers.present?
            args[:headers] = headers
            args[:headers].deep_stringify_keys!.deep_transform_values!(&:to_s) \
              if headers.is_a? Hash
          end

          producer.produce_sync(**args)
        end
        alias_method :raw_message, :sync_raw_message

        # Send a single message to Apache Kafka. The data is not touched, so
        # you need to encode it yourself before you pass it in. The destination
        # Kafka topic may be a relative name, or a hash which is passed to the
        # +.topic+ method to manipulate the application details. The message is
        # sent is an asynchronous, non-blocking way.
        #
        # @param data [Hash{Symbol => Mixed}] the raw data, unencoded
        # @param topic [String, Symbol, Hash{Symbol => Mixed}] the destination
        #   Apache Kafka topic
        # @param headers [Hash{String => String, Array<String>}, nil] the
        #   message headers to send
        # @param args [Hash{Symbol => Mixed}] additional parameters,
        #   see: https://bit.ly/4tHjcVg
        def async_raw_message(data:, topic:, headers: nil, **args)
          args = args.merge(topic: topic(topic), payload: data)

          # A compatibility helper for headers, as WaterDrop is now more strict
          if headers.present?
            args[:headers] = headers
            args[:headers].deep_stringify_keys!.deep_transform_values!(&:to_s) \
              if headers.is_a? Hash
          end

          producer.produce_async(**args)
        end
      end
    end
  end
end
