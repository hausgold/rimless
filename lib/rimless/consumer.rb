# frozen_string_literal: true

module Rimless
  # The global rimless Apache Kafka consumer application based on
  # the Karafka framework.
  #
  # rubocop:disable Style/ClassVars because we just work as a singleton
  class ConsumerApp < ::Karafka::App
    # We track our own initialization with this class variable
    @@rimless_initialized = false

    class << self
      # Initialize the Karafka framework and our global consumer application
      # with all our conventions/opinions.
      #
      # @return [Rimless::ConsumerApp] our self for chaining
      def initialize!
        # When already initialized, skip it
        return self if @@rimless_initialized

        # Initialize all the parts one by one
        initialize_rails!
        initialize_monitors!
        initialize_karafka!
        initialize_logger!
        initialize_code_reload!

        # Load the custom Karafka boot file when it exists, it contains
        # custom configurations and the topic/consumer routing table
        require ::Karafka.boot_file if ::Karafka.boot_file.exist?

        # Set our custom initialization process as completed to
        # skip subsequent calls
        @@rimless_initialized = true
        self
      end

      # Check if Rails is available and not already initialized, then
      # initialize it.
      def initialize_rails!
        rails_env = ::Karafka.root.join('config', 'environment.rb')

        # Stop, when Rails is already initialized
        return if defined? Rails

        # Stop, when there is no Rails at all
        return unless rails_env.exist?

        ENV['RAILS_ENV'] ||= 'development'
        ENV['KARAFKA_ENV'] = ENV.fetch('RAILS_ENV', nil)
        require rails_env
        Rails.application.eager_load!
      end

      # We like to listen to instrumentation and logging events to allow our
      # users to handle them like they need.
      def initialize_monitors!
        [
          WaterDrop::Instrumentation::StdoutListener.new,
          ::Karafka::Instrumentation::StdoutListener.new,
          ::Karafka::Instrumentation::ProctitleListener.new
        ].each do |listener|
          ::Karafka.monitor.subscribe(listener)
        end
      end

      # Configure the pure basics on the Karafka application.
      #
      # rubocop:disable Metrics/MethodLength because of the various settings
      # rubocop:disable Metrics/AbcSize dito
      def initialize_karafka!
        setup do |config|
          mapper = Rimless::Karafka::PassthroughMapper.new
          config.consumer_mapper = config.topic_mapper = mapper
          config.deserializer = Rimless::Karafka::AvroDeserializer.new
          config.kafka.seed_brokers = Rimless.configuration.kafka_brokers
          config.client_id = Rimless.configuration.client_id
          config.logger = Rimless.logger
          config.backend = :sidekiq
          config.batch_fetching = true
          config.batch_consuming = false
          config.shutdown_timeout = 10
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # When we run in development mode, we want to write the logs
      # to file and to stdout.
      def initialize_logger!
        return unless Rimless.env.development? && server?

        $stdout.sync = true
        Rimless.logger.extend(ActiveSupport::Logger.broadcast(
                                ActiveSupport::Logger.new($stdout)
                              ))
      end

      # Perform code hot-reloading when we are in Rails and in development
      # mode.
      def initialize_code_reload!
        return unless defined?(Rails) && Rails.env.development?

        ::Karafka.monitor.subscribe(::Karafka::CodeReloader.new(
                                      *Rails.application.reloaders
                                    ))
      end

      # Allows the user to re-configure the Karafka application if this is
      # needed. (eg. to set some ruby-kafka driver default settings, etc)
      #
      # @return [Rimless::ConsumerApp] our self for chaining
      def configure(&block)
        setup(&block)
        self
      end

      # Configure the topics-consumer routing table in a lean way.
      #
      # Examples:
      #
      #   topics({ app: :test_app, name: :admins } => YourConsumer)
      #   topics({ app: :test_app, names: %i[users admins] } => YourConsumer)
      #
      # @param topics [Hash{Hash => Class}] the topic to consumer mapping
      #
      # rubocop:disable Metrics/MethodLength because of the Karafka DSL
      def topics(topics)
        consumer_groups.draw do
          consumer_group Rimless.configuration.client_id do
            topics.each do |topic_parts, dest_consumer|
              Rimless.consumer.topic_names(topic_parts).each do |topic_name|
                topic(topic_name) do
                  consumer dest_consumer
                  worker Rimless::ConsumerJob
                  interchanger Rimless::Karafka::Base64Interchanger.new
                end
              end
            end
          end
        end

        self
      end
      # rubocop:enable Metrics/MethodLength

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

      # Check if we run as the Karafka server (consumer) process or not.
      #
      # @return [Boolean] whenever we run as the Karafka server or not
      def server?
        $PROGRAM_NAME.end_with?('karafka') && ARGV.include?('server')
      end
    end
  end
  # rubocop:enable Style/ClassVars

  # A rimless top-level concern which adds lean access to
  # the consumer application.
  module Consumer
    extend ActiveSupport::Concern

    class_methods do
      # A simple shortcut to fetch the Karafka consumer application.
      #
      # @return [Rimless::ConsumerApp] the Karafka consumer application class
      def consumer
        ConsumerApp.initialize!
      end
    end
  end
end
