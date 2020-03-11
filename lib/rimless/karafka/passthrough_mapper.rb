# frozen_string_literal: true

module Rimless
  module Karafka
    # The Karafka framework makes some assumptions about the consumer group and
    # topic names. We have our own opinions/conventions, so we just pass them
    # through unmodified.
    class PassthroughMapper
      # We do not want to modify the given consumer group name, so we
      # pass it through.
      #
      # @param raw_consumer_group_name [String, Symbol] the original
      #   consumer group name
      # @return [String, Symbol] the original consumer group name
      def call(raw_consumer_group_name)
        raw_consumer_group_name
      end

      # We do not want to modify the given topic name, so we pass it through.
      #
      # @param topic [String, Symbol] the original topic name
      # @return [String, Symbol] the original topic name
      def incoming(topic)
        topic
      end
      alias outgoing incoming
    end
  end
end
