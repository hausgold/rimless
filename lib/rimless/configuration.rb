# frozen_string_literal: true

module Rimless
  # The configuration for the rimless gem.
  class Configuration
    include ActiveSupport::Configurable

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

    # At least one broker of the Apache Kafka cluster
    config_accessor(:kafka_brokers) do
      ENV.fetch('KAFKA_BROKERS', 'kafka://message-bus.local:9092').split(',')
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

    # The Sidekiq job queue to use for consuming jobs
    config_accessor(:consumer_job_queue) do
      ENV.fetch('KAFKA_SIDEKIQ_JOB_QUEUE', 'default').to_sym
    end

    # A custom writer for the consumer job queue name.
    #
    # @param val [String, Symbol] the new job queue name
    def consumer_job_queue=(val)
      config.consumer_job_queue = val.to_sym
      # Refresh the consumer job queue
      Rimless::ConsumerJob.sidekiq_options(
        queue: Rimless.configuration.consumer_job_queue
      )
    end
  end
end
