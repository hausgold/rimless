# frozen_string_literal: true

module Rimless
  module Consumer
    # A simple consumer job, enqueued by the job bridge, after a message was
    # consumed from an Apache Kafka topic.
    class Job < ActiveJob::Base
      # Configure the default job queue
      queue_as Rimless.configuration.consumer_job_queue

      # Receive a single message/event from the Karafka process, consuming it
      # from a Apache Kafka topic. Within the context we "simulate" a Karafka
      # consumer context and run the configured consumer class (a user
      # application class, from +app/consumers/+) with the single message.
      #
      # The Karafka consumer context is just "simulated", as it does not
      # feature all components accessible by a regular Karafka consumer
      # context. This includes access to the real +coordinator+, or +client+.
      # But access to an +producer+ is provided. Check the
      # Rimless::Consumer::Base for more details.
      #
      # @param payload [Mixed] the (already) decoded Kafka message payload
      # @param consumer [String] the consumer class name to use
      # @param metadata [Hash] the Kafka message metadata (string/symbol
      #   keys are allowed)
      def perform(payload:, consumer:, metadata:)
        # Try to lookup the given consumer and create a new instance for it,
        # which is configured for the job context we're running in
        consumer = consumer.constantize.build_for_job(payload:, metadata:)
        # Run the actual consumer logic
        consumer.consume
      end
    end
  end
end
