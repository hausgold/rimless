# frozen_string_literal: true

require 'rimless'

# Setup the topic-consumer routing table and boot the consumer application
Rimless.consumer.topics(
  { app: :your_app, name: :your_topic } => CustomConsumer
).boot!

# Configure Karafka/ruby-kafka settings
# Rimless.consumer.configure do |config|
#   # See https://github.com/karafka/karafka/wiki/Configuration
#   # config.kafka.start_from_beginning = false
# end

# We want a less verbose logging on development
# Rimless.logger.level = Logger::INFO if Rails.env.development?

# Use a different Sidekiq queue for the consumer jobs
# Rimless.configuration.consumer_job_queue = :messages
