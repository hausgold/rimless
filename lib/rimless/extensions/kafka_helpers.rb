# frozen_string_literal: true

module Rimless
  module Extensions
    # The top-level Apache Kafka helpers.
    module KafkaHelpers
      extend ActiveSupport::Concern

      class_methods do
        # Generate a common topic name for Apache Kafka while taking care of
        # configured prefixes.
        #
        # @param args [Array<Mixed>] the relative topic name
        # @return [String] the complete topic name
        #
        # @example Name only
        #   Rimless.topic(:users)
        # @example Name with app
        #   Rimless.topic(:users, app: 'test-api')
        # @example Mix and match
        #   Rimless.topic(name: 'test', app: :fancy_app)
        # @example Full name - use as is
        #   Rimless.topic(full_name: 'my.custom.topic.name')
        def topic(*args)
          opts = args.last
          name = args.first if [String, Symbol].member?(args.first.class)

          if opts.is_a?(Hash)
            # When we got a full name, we use it as is
            return opts[:full_name] if opts.key? :full_name

            name = opts[:name] if opts.key?(:name)
            app = opts[:app] if opts.key?(:app)
          end

          name ||= nil
          app ||= Rimless.configuration.app_name

          raise ArgumentError, 'No name given' if name.nil?

          "#{Rimless.topic_prefix(app)}#{name}".tr('_', '-')
        end
      end
    end
  end
end
