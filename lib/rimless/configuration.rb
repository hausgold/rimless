# frozen_string_literal: true

module Rimless
  # The configuration for the rimless gem.
  class Configuration < ActiveSupport::OrderedOptions
    # Track our configurations settings (+Symbol+ keys) and their defaults as
    # lazy-loaded +Proc+'s values
    class_attribute :defaults,
                    instance_reader: true,
                    instance_writer: false,
                    instance_predicate: false,
                    default: {}

    # Create a new +Configuration+ instance with all settings populated with
    # their respective defaults.
    #
    # @param args [Hash{Symbol => Mixed}] additional settings which
    #   overwrite the defaults
    # @return [Configuration] the new configuration instance
    def initialize(**args)
      super()
      defaults.each { |key, default| self[key] = instance_exec(&default) }
      merge!(**args)
    end

    # A simple DSL method to define new configuration accessors/settings with
    # their defaults. The defaults can be retrieved with
    # +Configuration.defaults+ or +Configuration.new.defaults+.
    #
    # @param name [Symbol, String] the name of the configuration
    #   accessor/setting
    # @param default [Mixed, nil] a non-lazy-loaded static value, serving as a
    #   default value for the setting
    # @param block [Proc] when given, the default value will be lazy-loaded
    #   (result of the Proc)
    def self.config_accessor(name, default = nil, &block)
      # Save the given configuration accessor default value
      defaults[name.to_sym] = block || -> { default }

      # Compile reader/writer methods so we don't have to go through
      # +ActiveSupport::OrderedOptions#method_missing+.
      define_method(name) { self[name] }
      define_method("#{name}=") { |value| self[name] = value }
    end

    # Used to identity this client on the user agent header
    config_accessor(:app_name) { Rimless.local_app_name }

    # Environment to use
    config_accessor(:env) do
      next(ENV.fetch('KAFKA_ENV', Rails.env).to_sym) if defined? Rails

      ENV.fetch('KAFKA_ENV', 'development').to_sym
    end

    # The Apache Kafka client id (consumer group name)
    config_accessor(:client_id) do
      ENV.fetch('KAFKA_CLIENT_ID', Rimless.local_app_name)
    end

    # The logger instance to use (when available we use the +Rails.logger+)
    config_accessor(:logger) do
      next(Rails.logger) if defined? Rails

      Logger.new($stdout)
    end

    # Whenever the logger should be extended to write to stdout when
    # running in development environment (Rimless.env)
    config_accessor(:extend_dev_logger) { false }

    # At least one broker of the Apache Kafka cluster
    config_accessor(:kafka_brokers) do
      ENV.fetch('KAFKA_BROKERS', 'kafka://message-bus.local:9092')
         .split(',').map { |uri| uri.split('://', 2).last }.join(',')
    end

    # A custom writer for the kafka brokers configuration.
    #
    # @param val [String, Array<String>] the new kafka brokers list
    def kafka_brokers=(val)
      self[:kafka_brokers] =
        Array(val).join(',').split(',')
                  .map { |uri| uri.split('://', 2).last }
                  .join(',')
    end

    # The source Apache Avro schema files location (templates)
    config_accessor(:avro_schema_path) do
      path = %w[config avro_schemas]
      next(Rails.root.join(*path)) if defined? Rails

      Pathname.new(Dir.pwd).join(*path)
    end

    # The compiled Apache Avro schema files location (usable with Avro gem)
    config_accessor(:compiled_avro_schema_path) do
      path = %w[config avro_schemas compiled]
      next(Rails.root.join(*path)) if defined? Rails

      Pathname.new(Dir.pwd).join(*path)
    end

    # The Confluent Schema Registry API URL to use
    config_accessor(:schema_registry_url) do
      ENV.fetch('KAFKA_SCHEMA_REGISTRY_URL',
                'http://schema-registry.message-bus.local')
    end

    # This configuration allows users to configure a customized logger listener
    # (which is bound to +Rimless.logger+). When configured to a falsy value
    # (eg. +false+, or +nil+), no listener is installed by Rimless to Karafka.
    config_accessor(:consumer_logger_listener) do
      Karafka::Instrumentation::LoggerListener.new(
        log_polling: false
      )
    end

    # This setting allows users to configure a custom job bridge class, which
    # takes care of receiving Kafka messages and produce/enqueue ActiveJob
    # jobs. The configured class must be +Karafka::BaseConsumer+ compatible,
    # for Karafka.
    config_accessor(:job_bridge_class) { Rimless::Consumer::JobBridge }

    # This configuration allows to choose a different consumer job class,
    # enqueued by the +job_bridge_class+. This allows fully customized handling
    # on user applications.
    config_accessor(:consumer_job_class) { Rimless::Consumer::Job }

    # This configuration allows to choose the default Apache Avro deserializer
    # class, which is used by the Karafka consumer while using the
    # +Rimless.consumer.topics+ helper.
    config_accessor(:avro_deserializer_class) do
      Rimless::Consumer::AvroDeserializer
    end

    # The ActiveJob job queue to use for consuming jobs
    config_accessor(:consumer_job_queue) do
      ENV.fetch(
        'KAFKA_JOB_QUEUE',
        ENV.fetch('KAFKA_SIDEKIQ_JOB_QUEUE', 'default')
      ).to_sym
    end

    # A custom writer for the consumer job queue name.
    #
    # @param val [String, Symbol] the new job queue name
    def consumer_job_queue=(val)
      self[:consumer_job_queue] = val.to_sym

      # Refresh the consumer job queue
      consumer_job_class.queue_as(val)
    end

    # This configuration block allows users to fully customized the
    # +AvroTurf::Messaging+ instance. The Rimless default parameters hash is
    # injected as argument to the configured block. The result of the block is
    # then used to instantiate +AvroTurf::Messaging+, use like this.
    #
    #   ->(config) { config.merge(connect_timeout: 5) }
    #
    # See: https://bit.ly/4r0mDnw
    config_accessor(:avro_configure) { ->(config) { config } }

    # This configuration block allows users to fully customize the
    # +WaterDrop::Producer+ instance (accessible as +Rimless.producer+). The
    # Rimless settings are already applied when the block is called. The
    # +WaterDrop::Config+ is then injected as argument to the given block, and
    # can be used regular like this:
    #
    #   ->(config) { config.kafka[:'request.required.acks'] = -1 }
    #
    # See: https://bit.ly/4r5Uprv (+config.*+ root level WaterDrop settings)
    # See: https://bit.ly/3OtIfeu (+config.kafka+ settings)
    config_accessor(:producer_configure) { ->(config) { config } }

    # This configuration block allows users to fully customize the
    # +Karafka::App+ instance (accessible as +Rimless.consumer+). The Rimless
    # settings are already applied when the block is called. The
    # +Karafka::Setup::Config+ is then injected as argument to the given block,
    # and can be used regular like this:
    #
    #   ->(config) { config.kafka[:'request.required.acks'] = -1 }
    #
    # See: https://bit.ly/3MAF6Jk (+config.*+ root level Karafka settings)
    # See: https://bit.ly/3OtIfeu (+config.kafka+ settings)
    config_accessor(:consumer_configure) { ->(config) { config } }
  end
end
