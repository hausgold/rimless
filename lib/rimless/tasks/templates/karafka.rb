# frozen_string_literal: true

require 'rimless'

# Setup the topic-consumer routing table and boot the consumer application
Rimless.consumer.topics(
  { app: :your_app, name: :your_topic } => CustomConsumer
)

# Configure Karafka/ruby-kafka settings
# Rimless.consumer.configure do |config|
#   # See: https://bit.ly/3MAF6Jk (+config.*+ root level Karafka settings)
#   # See: https://bit.ly/3OtIfeu (+config.kafka+ settings)
#   # config.kafka[:'initial_offset'] = 'latest'
# end

# We want a less verbose logging on development
# Rimless.logger.level = Logger::INFO if Rails.env.development?

# Use a different ActiveJob queue for the consumer jobs
# Rimless.configuration.consumer_job_queue = :messages
