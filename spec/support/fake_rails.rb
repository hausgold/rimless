# frozen_string_literal: true

# Generate a fake Rails application class and instance for local application
# name detection. The result is a globally accessible +Rails.application+
# instance.
#
# @param class_name [String] the PascalCase'd name of the application class
def add_fake_rails_app(class_name)
  Object.const_set('Rails', Class.new { cattr_accessor :application })
  ::Rails.const_set('Application', Class.new)
  Object.const_set('IdentityApi', Class.new)

  app_namespace = class_name.constantize
  app_namespace.const_set('Application', Class.new(::Rails::Application))
  app_class = "#{class_name}::Application".constantize

  ::Rails.application = app_class.new
end

# Remove the fake Rails application class as well as the top-level +Rails+
# constant for cleanup.
#
# @param class_name [String] the PascalCase'd name of the application class
def remove_fake_rails_app(class_name)
  Object.send(:remove_const, :Rails)
  Object.send(:remove_const, class_name)
end
