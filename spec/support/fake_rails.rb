# frozen_string_literal: true

# Generate a fake Rails application class and instance for local application
# name detection. The result is a globally accessible +Rails.application+
# instance.
#
# @param class_name [String] the PascalCase'd name of the application class
def add_fake_rails_app(class_name)
  stub_const('Rails', Class.new { cattr_accessor :application })
  stub_const('Rails::Application', Class.new)
  stub_const('IdentityApi', Class.new)

  app_namespace = class_name.constantize
  app_namespace.const_set('Application', Class.new(Rails::Application))
  app_class = "#{class_name}::Application".constantize

  Rails.application = app_class.new
end
