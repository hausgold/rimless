# frozen_string_literal: true

module Rimless
  # The top-level configuration handling.
  #
  # rubocop:disable Style/ClassVars because we split module code
  module ConfigurationHandling
    extend ActiveSupport::Concern

    class_methods do
      # Retrieve the current configuration object.
      #
      # @return [Configuration]
      def configuration
        @@configuration ||= Configuration.new
      end

      # Configure the concern by providing a block which takes
      # care of this task. Example:
      #
      #   FactoryBot::Instrumentation.configure do |conf|
      #     # conf.xyz = [..]
      #   end
      def configure
        yield(configuration)
        configure_dependencies
      end

      # Reset the current configuration with the default one.
      def reset_configuration!
        @@configuration = Configuration.new
      end

      # Retrieve the current configured environment. You can use it like
      # +Rails.env+ to query it. E.g. +Rimless.env.production?+.
      #
      # @return [ActiveSupport::StringInquirer] the environment
      def env
        @@env = ActiveSupport::StringInquirer.new(configuration.env.to_s) \
          if @env.to_s != configuration.env.to_s
        @@env
      end

      # A simple convention helper to setup Apache Kafka topic names.
      #
      # @param app [String] the application namespace
      # @return [String] the Apache Kafka topic name prefix
      def topic_prefix(app = Rimless.configuration.app_name)
        "#{Rimless.env}.#{app}."
      end

      # Pass back the local application name. When we are loaded together with
      # a Rails application we use the application class name. This
      # application name is URI/GID compatible. When no local application is
      # available, we just pass back +nil+.
      #
      # @return [String, nil] the Rails application name, or +nil+
      def local_app_name
        # Check for non-Rails integration
        return unless defined? Rails
        # Check if a application is defined
        return if Rails.application.nil?

        # Pass back the URI compatible application name
        Rails.application.class.parent_name.underscore.dasherize
      end

      # Retrieve the current configured logger instance.
      #
      # @return [Logger] the logger instance
      delegate :logger, to: :configuration
    end
  end
  # rubocop:enable Style/ClassVars
end
