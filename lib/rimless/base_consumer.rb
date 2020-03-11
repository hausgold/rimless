# frozen_string_literal: true

module Rimless
  # The base consumer where all Apache Kafka messages will be processed. It
  # comes with some simple conventions to keep the actual application code
  # simple to use.
  class BaseConsumer < ::Karafka::BaseConsumer
    # A generic message consuming handler which resolves the message event name
    # to an actual method. All message data (top-level keys) is passed down to
    # the event method as symbol arguments.
    def consume
      # We ignore events we do not handle by definition
      send(event, **arguments) if respond_to? event
    end

    # Prepare the message payload as event method arguments.
    #
    # @return [Hash{Symbol => Mixed}] the event method arguments
    def arguments
      params.payload.except(:event)
    end

    # A shortcut to fetch the event name from the Kafka message.
    #
    # @return [Symbol] the event name of the current message
    def event
      params.payload[:event].to_sym
    end
  end
end
