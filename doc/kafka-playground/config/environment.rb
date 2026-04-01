# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'active_support'
require 'active_support/all'
require 'json'

Bundler.require(:default)
ActiveSupport.eager_load!

AppLogger = Logger.new($stdout)
AppLogger.level = Logger::FATAL
AppLogger.level = Logger::DEBUG if ENV.fetch('DEBUG', '').match?(/true|1|on/)

Dir[File.expand_path('initializers/*.rb', __dir__)].each { |f| require f }

def args!
  app = Thor.descendants.map(&:to_s)
            .reject { |klass| klass.include? '::' }.first
  raise 'No Thor application class was found.' unless app

  app = app.constantize

  help = ARGV.any? { |arg| %w[help -h --help].include?(arg) }
  known_cmd = app.all_tasks.key? ARGV.first

  if ARGV.blank? || help || known_cmd
    ARGV.replace(['help', app.default_task])
  else
    ARGV.unshift(app.default_task)
  end

  ARGV
end

def debug!(opts)
  AppLogger.level = Logger::DEBUG if opts[:verbose]
end
