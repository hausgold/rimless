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
      def avro_parse(data, **)
        Rimless.avro_decode(data, **)
      end

      # A simple helper to generate Apache Kafka message doubles for consuming.
      #
      # @param payload [Hash{Symbol => Mixed}] the message payload
      # @param topic [String, Hash{Symbol => Mixed}] the actual message
      #   topic (full as string, or parts via hash)
      # @param metadata [Hash{Symbol => Mixed}] the message metadata
      # @return [RSpec::Mocks::InstanceVerifyingDouble] the Kafka message double
      #
      # rubocop:disable Metrics/MethodLength -- because of the metadata handling
      def kafka_message(topic: nil, headers: {}, metadata: {}, **payload)
        metadata = {
          topic: topic ? Rimless.topic(topic) : nil,
          partition: 0,
          offset: 206,
          key: nil,
          headers: headers,
          timestamp: Time.current,
          received_at: Time.current,
          **metadata
        }

        instance_double(
          Karafka::Messages::Message,
          deserialized?: true,
          tombstone?: false,
          payload: payload,
          metadata: instance_double(
            Karafka::Messages::Metadata,
            **metadata,
            to_h: metadata
          ),
          **metadata
        )
      end
      # rubocop:enable Metrics/MethodLength

      # Capture all Apache Kafka messages of the given block.
      #
      # @yield the given block to capture the messages
      # @return [Array<Hash{Symbol => Mixed}>] the captured messages
      def capture_kafka_messages(&)
        Rimless::RSpec::Matchers::HaveSentKafkaMessage.new(nil).capture(&)
      end

      # An augmented helper for +karafka.consumer_for+, provided by the
      # +karafka-testing+ gem to locate and instantiate a consumer. When the
      # found consumer features the Rimless job bridge consumer logic, the
      # +enqueue_job+ is replaced to not enqueue the job, but perform it
      # inline. Otherwise the end-user consumer logic is not executed, which is
      # clearly the user expectation.
      #
      # @param topic [String] the full topic name, use +Rimless.topic+ if
      #   needed
      # @return [Karafka::BaseConsumer] the found consumer
      def kafka_consumer_for(topic)
        # The +karafka+ helper is provided by the +karafka-testing+ gem
        karafka.consumer_for(topic).tap do |consumer|
          # When we're not dealing with a regular Rimless job bridge consumer,
          # we skip further processing
          next unless consumer.respond_to? :enqueue_job

          # Otherwise rig the job bridging and run the wrapped consumer instead
          allow(consumer).to receive(:enqueue_job) do |message|
            Rimless.configuration.consumer_job_class.perform_now(
              **consumer.message_to_job_args(message)
            )
          end
        end
      end
    end
  end
end
