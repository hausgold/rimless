# frozen_string_literal: true

namespace :rimless do
  # rubocop:disable Rails/RakeEnvironment -- because this is just an command
  #   proxy, no need for an application bootstrap
  desc 'Start the Apache Kafka consumer'
  task :consumer do
    system 'bundle exec karafka server'
  end
  # rubocop:enable Rails/RakeEnvironment

  desc 'Print all the consumer routes'
  task routes: :environment do
    require 'rimless'

    Rimless.consumer.routes.each do |consumer_group|
      consumer_group.topics.each do |topic|
        name = topic.name.split('.')[1..].join('.')

        consumer = topic.consumer
        consumer = consumer.consumer.constantize \
          if consumer.new.is_a? Rimless::Consumer::JobBridge

        base_methods = consumer.superclass.new.methods
        event_methods = (consumer.new.methods - base_methods).sort

        event_methods = if event_methods.count > 3
                          event_methods.join("\n##{' ' * 20}")
                        else
                          event_methods.join(', ')
                        end

        puts <<~INFO
          # Topic (canonical): #{name}
          # Topic (full name): #{topic.name}
          #          Consumer: #{consumer}
          #            Events: #{event_methods}
        INFO
        puts
      end
    end
  end
end
