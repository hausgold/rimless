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

    Rimless.consumer.consumer_groups.each do |consumer_group|
      consumer_group.topics.each do |topic|
        name = topic.name.split('.')[1..].join('.')

        puts "#    Topic: #{name}"
        puts "# Consumer: #{topic.consumer}"

        base = topic.consumer.superclass.new(topic).methods
        events = topic.consumer.new(topic).methods - base

        puts "#   Events: #{events.join(', ')}"
        puts
      end
    end
  end
end
