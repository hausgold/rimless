# frozen_string_literal: true

module Rimless
  module Karafka
    # Allow the +karafka-sidekiq-backend+ gem to transfer binary Apache Kafka
    # messages to the actual Sidekiq job.
    #
    # rubocop:disable Security/MarshalLoad -- because we encode/decode the
    #   messages in our own controlled context
    class Base64Interchanger < ::Karafka::Interchanger
      # Encode a binary Apache Kafka message(s) so they can be passed to the
      # Sidekiq +Rimless::ConsumerJob+.
      #
      # @param params_batch [Karafka::Params::ParamsBatch] the karafka params
      #   batch object
      # @return [String] the marshaled+base64 encoded data
      def encode(params_batch)
        Base64.encode64(Marshal.dump(super))
      end

      # Decode the binary Apache Kafka message(s) so they can be processed by
      # the Sidekiq +Rimless::ConsumerJob+.
      #
      # @param params_string [String] the marshaled+base64 encoded data
      # @return [Array<Hash>] the unmarshaled+base64 decoded data
      def decode(params_batch)
        super(Marshal.load(Base64.decode64(params_batch))).map(&:stringify_keys)
      end
    end
    # rubocop:enable Security/MarshalLoad
  end
end
