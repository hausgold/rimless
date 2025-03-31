# frozen_string_literal: true

module Rimless
  # Some general RSpec testing stuff.
  module RSpec
    # A set of Rimless/RSpec matchers.
    module Matchers
      # The Apache Kafka message expectation.
      #
      # rubocop:disable Metrics/ClassLength -- because its almost RSpec API
      #   code
      class HaveSentKafkaMessage < ::RSpec::Matchers::BuiltIn::BaseMatcher
        include ::RSpec::Mocks::ExampleMethods

        # Instantiate a new expectation object.
        #
        # @param schema [String, Symbol, nil] the expected message schema
        # @return [HaveSentKafkaMessage] the expectation instance
        def initialize(schema)
          super
          @schema = schema
          @args = {}
          @data = {}
          @messages = []
          set_expected_number(:exactly, 1)
        end

        # Capture all Apache Kafka messages of the given block.
        #
        # @yield the given block to capture the messages
        # @return [Array<Hash{Symbol => Mixed}>] the captured messages
        def capture(&block)
          matches?(block)
          @messages
        end

        # Collect the expectation arguments for the Kafka message passing. (eg.
        # topic)
        #
        # @param args [Hash{Symbol => Mixed}] the expected arguments
        # @return [HaveSentKafkaMessage] the expectation instance
        def with(**args)
          @args = args
          self
        end

        # Collect the expectations for the encoded message. The passed message
        # will be decoded accordingly for the check.
        #
        # @param args [Hash{Symbol => Mixed}] the expected arguments
        # @return [HaveSentKafkaMessage] the expectation instance
        def with_data(**args)
          @data = args
          self
        end

        # Set the expected amount of message (exactly).
        #
        # @param count [Integer] the expected amount
        # @return [HaveSentKafkaMessage] the expectation instance
        def exactly(count)
          set_expected_number(:exactly, count)
          self
        end

        # Set the expected amount of message (at least).
        #
        # @param count [Integer] the expected amount
        # @return [HaveSentKafkaMessage] the expectation instance
        def at_least(count)
          set_expected_number(:at_least, count)
          self
        end

        # Set the expected amount of message (at most).
        #
        # @param count [Integer] the expected amount
        # @return [HaveSentKafkaMessage] the expectation instance
        def at_most(count)
          set_expected_number(:at_most, count)
          self
        end

        # Just syntactic sugar.
        #
        # @return [HaveSentKafkaMessage] the expectation instance
        def times
          self
        end

        # Just syntactic sugar for a regular +exactly(:once)+ call.
        #
        # @return [HaveSentKafkaMessage] the expectation instance
        def once
          exactly(:once)
        end

        # Just syntactic sugar for a regular +exactly(:twice)+ call.
        #
        # @return [HaveSentKafkaMessage] the expectation instance
        def twice
          exactly(:twice)
        end

        # Just syntactic sugar for a regular +exactly(:thrice)+ call.
        #
        # @return [HaveSentKafkaMessage] the expectation instance
        def thrice
          exactly(:thrice)
        end

        # Serve the RSpec matcher API and signalize we support block evaluation.
        #
        # @return [Boolean] the answer
        def supports_block_expectations?
          true
        end

        # The actual RSpec API check for the expectation.
        #
        # @param proc [Proc] the block to evaluate
        # @return [Boolean] whenever the check was successful or not
        def matches?(proc)
          unless proc.is_a? Proc
            raise ArgumentError, 'have_sent_kafka_message and ' \
                                 'sent_kafka_message only support block ' \
                                 'expectations'
          end

          listen_to_messages
          proc.call
          check
        end

        # The actual RSpec API check for the expectation (negative).
        #
        # @param proc [Proc] the block to evaluate
        # @return [Boolean] whenever the check was unsuccessful or not
        #
        # rubocop:disable Naming/PredicateName -- because we just serve
        #   the RSpec API here
        def does_not_match?(proc)
          set_expected_number(:at_least, 1)

          !matches?(proc)
        end
        # rubocop:enable Naming/PredicateName

        private

        # Set the expectation type and count for the checking.
        #
        # @param relativity [Symbol] the amount expectation type
        # @param count [Integer] the expected amount
        def set_expected_number(relativity, count)
          @expectation_type = relativity
          @expected_number = case count
                             when :once then 1
                             when :twice then 2
                             when :thrice then 3
                             else Integer(count)
                             end
        end

        # Perform the result set checking of recorded message which were sent.
        #
        # @return [Boolean] the answer
        def check
          @matching, @unmatching = @messages.partition do |message|
            schema_match?(message) && arguments_match?(message) &&
              data_match?(message)
          end

          @matching_count = @matching.size

          case @expectation_type
          when :exactly then @expected_number == @matching_count
          when :at_most then @expected_number >= @matching_count
          when :at_least then @expected_number <= @matching_count
          end
        end

        # Check for the expected schema on the given message.
        #
        # @param message [Hash{Symbol => Mixed}] the message under inspection
        # @return [Boolean] the check result
        def schema_match?(message)
          return true unless @schema

          begin
            Rimless.avro.decode(message[:encoded_data],
                                schema_name: @schema.to_s)
            true
          rescue Avro::IO::SchemaMatchException
            false
          end
        end

        # Check for the expected arguments on the Kafka message producer call.
        #
        # @param message [Hash{Symbol => Mixed}] the message under inspection
        # @return [Boolean] the check result
        def arguments_match?(message)
          return true unless @args.any?

          ::RSpec::Mocks::ArgumentListMatcher.new(*@args)
                                             .args_match?(*message[:args])
        end

        # Check for the expected data on the encoded Apache Avro message.
        # (deep include)
        #
        # @param message [Hash{Symbol => Mixed}] the message under inspection
        # @return [Boolean] the check result
        def data_match?(message)
          return true unless @data.any?

          message[:data].merge(@data.deep_stringify_keys) == message[:data]
        end

        # Setup the +WaterDrop+ spies and record each sent message.
        # because of the message decoding
        # rubocop:disable Metrics/MethodLength -- dito
        def listen_to_messages
          decode = proc do |encoded|
            { encoded_data: encoded, data: Rimless.avro.decode(encoded) }
          end

          allow(WaterDrop::SyncProducer).to receive(:call) do |data, **args|
            @messages << { args: args, type: :sync }.merge(decode[data])
            nil
          end

          allow(WaterDrop::AsyncProducer).to receive(:call) do |data, **args|
            @messages << { args: args, type: :async }.merge(decode[data])
            nil
          end
        end
        # rubocop:enable Metrics/MethodLength

        # Serve the RSpec API and return the positive failure message.
        #
        # @return [String] the message to display
        def failure_message
          result = ["expected to send #{base_message}"]

          if @unmatching.any?
            result << "\nSent messages:"
            @unmatching.each do |message|
              result << "\n  #{base_message_detail(message)}"
            end
          end

          result.join
        end

        # Serve the RSpec API and return the negative failure message.
        #
        # @return [String] the message to display
        def failure_message_when_negated
          "expected not to send #{base_message}"
        end

        # The base error message with all the expectation details included.
        #
        # @return [String] the expectation details message
        def base_message
          expectation_mod = @expectation_type.to_s.humanize.downcase
          result = ["#{expectation_mod} #{@expected_number} messages,"]

          result << " with schema #{@schema}," if @schema
          result << " with #{@args}," if @args.any?
          result << " with data #{@data}," if @data.any?
          result << " but sent #{@matching_count}"

          result.join
        end

        # The expectation details of a single message when unmatching messages
        # were found.
        #
        # @return [String] the expectation details of a single message
        def base_message_detail(message)
          result = ['message']

          result << " with #{message[:args]}" if message[:args].any?
          result << " with data: #{message[:data]}"

          result.join
        end
      end
      # rubocop:enable Metrics/ClassLength

      # Check for messages which were sent to Apache Kafka by the given block.
      #
      # @param schema [String, Symbol, nil] the Apache Avro schema to check
      #
      # rubocop:disable Naming/PredicateName -- because its a RSpec matcher
      def have_sent_kafka_message(schema = nil)
        HaveSentKafkaMessage.new(schema)
      end
      alias sent_kafka_message have_sent_kafka_message
      # rubocop:enable Naming/PredicateName
    end
  end
end
