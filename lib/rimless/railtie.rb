# frozen_string_literal: true

module Rimless
  # Rails-specific initializations.
  class Railtie < Rails::Railtie
    # Run before all Rails initializers, but after the application is defined
    config.before_initialize do
      conf = Rimless.configuration
      app_name = Rimless.local_app_name

      # Reset the default application name (which is +nil+), because the Rails
      # application was not defined when the rimless gem was loaded
      conf.app_name = app_name

      # Set the app name as default client id, when not already set
      conf.client_id ||= app_name

      # When the code statistics feature is available,
      # register application consumers
      Rails::CodeStatistics.register_directory('Consumers', 'app/consumers') \
        if defined?(Rails::CodeStatistics)

      # Karafka tries forcefully to load its bootfile, when it detects a
      # Rails application (via railtie). This may fail on applications
      # which use Rimless just for message producing. So we configure a
      # special setting for Karafka to skip its loading.
      # See: https://bit.ly/4uuqFaI
      ENV['KARAFKA_BOOT_FILE'] = 'false' unless Karafka.boot_file.exist?
    end

    # Run after all configuration is set via Rails initializers
    config.after_initialize do
      # Reconfigure our dependencies
      Rimless.configure_dependencies
    end

    # Load all our Rake tasks if we're supposed to do
    rake_tasks do
      Dir[File.join(__dir__, 'tasks', '*.rake')].each { |file| load file }
    end
  end
end
