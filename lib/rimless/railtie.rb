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
    end

    # Run after all configuration is set via Rails initializers
    config.after_initialize do
      # Reconfigure our dependencies
      Rimless.configure_dependencies
    end
  end
end
