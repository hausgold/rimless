# frozen_string_literal: true

module Rimless
  # Some general RSpec testing stuff.
  module RSpec
    # A collection of Rimless/RSpec helpers.
    module Helpers
      # A simple helper to parse a blob of Apache Avro data.
      #
      # @param data [String] the Apache Avro blob
      # @param opts [Hash{Symbol => Mixed}] additional options
      # @return [Hash{String => Mixed}] the parsed payload
      def avro_parse(data, **opts)
        Rimless.avro_decode(data, **opts)
      end

      # A simple helper to fake a deserialized Apache Kafka message for
      # consuming.
      #
      # @param payload [Hash{Symbol => Mixed}] the message payload
      # @param topic [String, Hash{Symbol => Mixed}] the actual message
      #   topic (full as string, or parts via hash)
      # @return [OpenStruct] the fake deserialized Kafka message
      #
      # rubocop:disable Metrics/MethodLength -- because of the various
      #   properties
      # rubocop:disable Style/OpenStructUse -- because existing specs may rely
      #   on this data type
      def kafka_message(topic: nil, headers: {}, **payload)
        OpenStruct.new(
          topic: Rimless.topic(topic),
          headers: headers,
          payload: payload,
          is_control_record: false,
          key: nil,
          offset: 206,
          partition: 0,
          create_time: Time.current,
          receive_time: Time.current,
          deserialized: true
        )
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Style/OpenStructUse

      # Capture all Apache Kafka messages of the given block.
      #
      # @yield the given block to capture the messages
      # @return [Array<Hash{Symbol => Mixed}>] the captured messages
      def capture_kafka_messages(&block)
        Rimless::RSpec::Matchers::HaveSentKafkaMessage.new(nil).capture(&block)
      end
    end
  end
end
