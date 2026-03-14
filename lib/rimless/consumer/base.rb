# frozen_string_literal: true

module Rimless
  module Consumer
    # The base consumer where all Apache Kafka messages will be processed,
    # within an ActiveJob job. It comes with some simple conventions to keep
    # the actual application code simple to use. Example usage on an
    # application:
    #
    #   app/consumers/my_consumer.rb
    #
    #   class IdentityApiConsumer < ApplicationConsumer
    #     # Handle +identity-api.users/user_locked+ messages.
    #     #
    #     # @param user [Hash{Symbol => Mixed}] the event user data
    #     # @param args [Hash{Symbol => Mixed}] additional event data
    #     def user_locked(user:, **args)
    #       # ..
    #     end
    #   end
    #
    # Despite its default usage within an ActiveJob context, it still directly
    # usable by Karafka. Just be warned that, when running inside a ActiveJob
    # context, it lack support for various Karafka internals (eg. coordinator,
    # client, etc).
    class Base < Karafka::BaseConsumer
      # Allow to handle a single message, each at a time
      attr_accessor :message
      # Allow older clients to access the current message as +params+, and the
      # current messages batch as +params_batch+ (Karafka 1.4 style)
      alias params message
      alias params_batch messages

      # Build a new disposable consumer instance for a single Apache Kafka
      # message, which should be processed within the AciveJob context.
      #
      # @param payload [Mixed] the (already) decoded Kafka message payload
      # @param metadata [Hash] the Kafka message metadata (string/symbol
      #   keys are allowed)
      # @return [Rimless::Consumer::Base] the job context-aware consumer
      #   instance
      def self.build_for_job(payload:, metadata:)
        new.tap do |consumer|
          metadata = metadata.symbolize_keys

          consumer.coordinator = OpenStruct.new(
            topic: metadata[:topic],
            partition: metadata[:partition]
          )
          consumer.producer = Rimless.producer

          metadata = Karafka::Messages::Metadata.new(
            **metadata.except(:key, :headers),
            raw_key: metadata[:key],
            raw_headers: metadata[:headers],
            deserializers: job_deserializers
          )
          consumer.messages =
            [Karafka::Messages::Message.new(payload, metadata)]
        end
      end

      # A custom set of Karafka deserializers, exclusive for the AciveJob
      # context. As we already get the deserialized details (payload, message
      # key, message headers), we just want to pass the values through.
      #
      # @return [Karafka::Routing::Features::Deserializers::Config] the
      #   deserializers config object
      def self.job_deserializers
        @job_deserializers ||=
          Karafka::Routing::Features::Deserializers::Config.new(
            active: true,
            payload: ->(message) { message.raw_payload },
            key: Karafka::Deserializers::Key.new,
            headers: Karafka::Deserializers::Headers.new
          )
      end

      # A generic message consuming handler which resolves the message event
      # name to an actual method. All message data (top-level keys) is passed
      # down to the event method as symbol arguments.
      def consume
        messages.each do |message|
          self.message = message

          # We ignore events we do not handle by definition
          send(event, **arguments) if !event.nil? && respond_to?(event)
        end
      end

      # Prepare the message payload as event method arguments.
      #
      # @return [Hash{Symbol => Mixed}] the event method arguments
      def arguments
        event_name_key = :event
        event_name_key = 'event' if message.payload.key? 'event'
        message.payload.except(event_name_key)
      end

      # A shortcut to fetch the event name from the Kafka message.
      #
      # @return [Symbol] the event name of the current message
      def event
        event_name = message.payload[:event]
        event_name ||= message.payload['event']
        event_name&.to_sym
      end
    end
  end
end
