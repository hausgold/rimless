# frozen_string_literal: true

module Rimless
  module Consumer
    # The consumer application which adds some convenience helpers and
    # library-related configurations.
    class App < Karafka::App
      # Allow accessing the class-level configuration methods from our instance
      delegate :setup, :routes, to: self

      # Creates a new Rimless/Karafka application instance while configuring
      # our library defaults.
      #
      # @return [Rimless::Consumer::App] the configured consumer application
      #
      # rubocop:disable Metrics/MethodLength -- because of the Karafka
      #   configuration
      def initialize
        # Run the parent class initialization
        super

        setup do |config|
          # See: https://bit.ly/3OtIfeu (+config.kafka+ settings)

          # An optional identifier of a Kafka consumer (in a consumer group)
          # that is passed to a Kafka broker with every request. A logical
          # application name to be included in Kafka logs and monitoring
          # aggregates.
          config.kafka[:'client.id'] = Rimless.configuration.client_id
          # All the known brokers, at least one. The ruby-kafka driver will
          # discover the whole cluster structure once and when issues occur
          # to dynamically adjust scaling operations.
          config.kafka[:'bootstrap.servers'] =
            Rimless.configuration.kafka_brokers
          # All brokers MUST acknowledge a new message by default
          config.kafka[:'request.required.acks'] = -1

          # See: https://bit.ly/3MAF6Jk (+config.*+ settings)

          # Used to uniquely identify given client instance - for logging only
          config.client_id = [
            Rimless.configuration.client_id,
            Process.pid,
            Socket.gethostname
          ].join('-')

          # Should be unique per application to properly track message
          # consumption. See: Kafka Consumer Groups.
          config.group_id = Rimless.configuration.client_id

          # We use dots (parts separation) and underscores for topic names, by
          # convention.
          config.strict_topics_namespacing = false

          # Number of milliseconds after which Karafka no longer waits for the
          # consumers to stop gracefully but instead we force terminate
          # everything.
          config.shutdown_timeout = 10.seconds.in_milliseconds

          # Recreate consumers with each batch. This will allow Rails code
          # reload to work in the development mode. Otherwise Karafka process
          # would not be aware of code changes.
          config.consumer_persistence = Rimless.env.production?

          # Use our logger instead
          config.logger = Rimless.logger
        end

        # Add the logging listener to Karafka in order to facilitate our gem
        # logger. When the user configuration results in an falsy value (eg.
        # +nil+ or +false+), we skip it.
        listener = Rimless.configuration.consumer_logger_listener
        Karafka.monitor.subscribe(listener) if listener

        # Configure some routing defaults
        routes.draw do
          defaults do
            deserializers(
              payload: Rimless.configuration.avro_deserializer_class.new
            )
          end
        end

        # Call the user-configurable block with our configuration
        # for customizations
        setup(&Rimless.configuration.consumer_configure)
      end
      # rubocop:enable Metrics/MethodLength

      # Configure the topics-consumer routing table in a lean way.
      #
      # Examples:
      #
      #   topics({ app: :test_app, name: :admins } => YourConsumer)
      #   topics({ app: :test_app, names: %i[users admins] } => YourConsumer)
      #
      # Examples:
      #
      #   topics(
      #     { app: :test_app, name: :admins } => lambda { |topic|
      #       consumer Rimless::Consumer::JobBridge.build(dest_consumer)
      #     }
      #   )
      #
      # Examples:
      #
      #   topics do
      #     topic('name') do
      #       consumer CustomConsumer
      #     end
      #   end
      #
      # @param topics [Hash{Hash => Class, Proc}] the topic to consumer mapping
      # @yield the given block on the routing table
      # @return [Rimless::Consumer::App] the application instance for chaining
      def topics(topics = [], &block)
        routes.draw do
          consumer_group(Rimless.configuration.client_id) do
            instance_exec(&block) if block_given?

            topics.each do |topic_parts, dest_consumer|
              Rimless.consumer.topic_names(topic_parts).each do |topic_name|
                configure = proc do
                  consumer(
                    Rimless.configuration.job_bridge_class.build(dest_consumer)
                  )
                  deserializers(
                    payload: Rimless.configuration.avro_deserializer_class.new
                  )
                end
                configure = dest_consumer if dest_consumer.is_a? Proc
                topic(topic_name, &configure)
              end
            end
          end
        end

        self
      end

      # Build the conventional Apache Kafka topic names from the given parts.
      # This allows various forms like single strings/symbols and a hash in the
      # form of +{ app: [String, Symbol], name: [String, Symbol], names:
      # [Array<String, Symbol>] }+. This allows the maximum of flexibility.
      #
      # @param parts [String, Symbol, Hash{Symbol => Mixed}] the topic
      #   name parts
      # @return [Array<String>] the full topic names
      def topic_names(parts)
        # We have a single app, but multiple names so we handle them
        if parts.is_a?(Hash) && parts.key?(:names)
          return parts[:names].map do |name|
            Rimless.topic(parts.merge(name: name))
          end
        end

        # We cannot handle the given input
        [Rimless.topic(parts)]
      end

      # Allows the user to re-configure the Karafka application if this is
      # needed. (eg. to set some kafka driver settings, etc)
      #
      # @yield [Karafka::Setup::ConfigProxy] the given block to allow
      #   configuration manipulation
      # @return [Rimless::Consumer::App] our self for chaining
      def configure(&)
        setup(&)
        self
      end
    end
  end
end
