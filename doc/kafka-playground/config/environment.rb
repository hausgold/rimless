# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'active_support'
require 'active_support/all'
require 'json'
require 'pp'

Bundler.require(:default)
ActiveSupport.eager_load!

AppLogger = Logger.new(STDOUT)
AppLogger.level = Logger::FATAL
AppLogger.level = Logger::DEBUG if ENV.fetch('DEBUG', '').match? /true|1|on/

Rimless.configure do |conf|
  conf.env = 'production'
  conf.app_name = 'playground_app'
  conf.client_id = 'playground'
  conf.logger = AppLogger
  conf.kafka_brokers = ['kafka://kafka.playground.local:9092']
  conf.schema_registry_url = 'http://schema-registry.playground.local'
end

KafkaClient = Kafka.new(Rimless.configuration.kafka_brokers, logger: AppLogger)

# +Resolv+ is a thread-aware DNS resolver library written in Ruby. Some newer
# networking libraries like excon (>=0.85.0) makes use of it instead of the
# regular glibc facility. This raises an issue for our local development as we
# use the mDNS stack which is configured in every Docker image accordingly
# (Avahi, libnss[-mdns]). The default resolver of +Resolv+ does not include the
# mDNS stack so we have to reconfigure it here for local usage only.
#
# See: https://docs.ruby-lang.org/en/2.7.0/Resolv.html
require 'resolv'
Resolv::DefaultResolver.replace_resolvers(
  [
    Resolv::Hosts.new,
    Resolv::MDNS.new,
    Resolv::DNS.new
  ]
)

def topic?(name)
  @topic_conf = KafkaClient.describe_topic(name)
rescue Kafka::UnknownTopicOrPartition
  false
end

def args!
  app = Thor.descendants.map(&:to_s)
                        .reject { |klass| klass.include? '::' }.first
  raise "No Thor application class was found." unless app
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
