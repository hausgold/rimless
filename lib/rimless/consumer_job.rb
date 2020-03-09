# frozen_string_literal: true

module Rimless
  # The base consumer job where each message is processed asynchronous via
  # Sidekiq. We need to inherit the Karafka base worker class into a custom
  # one, otherwise it fails.
  class ConsumerJob < ::Karafka::BaseWorker
    sidekiq_options queue: Rimless.configuration.consumer_job_queue
  end
end
