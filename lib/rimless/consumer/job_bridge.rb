# frozen_string_literal: true

module Rimless
  module Consumer
    # This is our default consumer for Karafka, which wraps the actual user
    # consumer classes, consumes all message of a batch and enqueues them as
    # ActiveJob job. It builds a bridge between the Karafka topic/message
    # consumer process and a later running ActiveJob processor (eg. Sidekiq or
    # Solid Queue).
    class JobBridge < Karafka::BaseConsumer
      # Persist the wrapped consumer, to pass it later while enqueuing jobs
      class_attribute :consumer

      class << self
        # Build a new anonymous wrapper class, based on the given destination
        # consumer class.
        #
        # @param consumer [Class] the consumer to pass down to the jobs
        # @return [Class] the new and configured wrapper class
        def build(consumer)
          # We cannot serialize anonymous classes, as they need to cross
          # process borders via ActiveJob here, and the resulting job needs to
          # constantize the serialized class name again
          raise ArgumentError, "Anonymous consumer class passed: #{consumer}" \
            unless consumer.name

          Class.new(self).tap do |wrapper|
            wrapper.consumer = consumer.name
          end
        end

        # A custom object/class inspection helper to allow pretty printing of
        # the anonymous class.
        #
        # @return [String] the pretty-printed class/instance
        def inspect
          # When not an anonymous class
          return super unless name.nil?

          # Otherwise the anonymous wrapper class
          "#{Rimless::Consumer::JobBridge.name}[consumer=#{consumer.inspect}]"
        end
        alias to_s inspect
      end

      # Consume all messages of the current batch, and mark each message
      # afterwards as processed (asynchronous). You can simply overwrite this
      # method if you need more precise control of the message processing,
      # eg. just using marking the whole batch processed, or custom error
      # handling.
      #
      # See: https://bit.ly/4aPXaai - then configure your own
      # `Rimless.configuration.job_bridge_class`.
      def consume
        messages.each do |message|
          enqueue_job(message)
          mark_as_consumed(message)
        end
      end

      # Enqueue a new job for the given message.
      #
      # @param message [Karafka::Messages::Message] the message to enqueue
      def enqueue_job(message)
        Rimless.configuration.consumer_job_class.perform_later(
          **message_to_job_args(message)
        )
      end

      # Convert the given +Karafka::Messages::Message+ instance to a simple
      # hash, which can be transported by ActiveJob.
      #
      # @param message [Karafka::Messages::Message] the message to enqueue
      # @return [Hash{Symbol => Mixed}] the job argument
      def message_to_job_args(message)
        {
          payload: message.payload,
          consumer:,
          metadata: message.metadata.to_h.slice(
            :topic,
            :partition,
            :offset,
            :timestamp,
            :received_at
          ).merge(
            key: message.metadata.key,
            headers: message.metadata.headers
          )
        }
      end

      # A custom object/class inspection helper to allow pretty printing of
      # the anonymous class.
      #
      # @return [String] the pretty-printed class/instance
      def inspect
        "#<#{Rimless::Consumer::JobBridge.name} consumer=#{consumer.inspect}>"
      end
      alias to_s inspect
    end
  end
end
