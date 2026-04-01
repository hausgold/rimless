# frozen_string_literal: true

Rimless.configure do |conf|
  conf.env = 'production'
  conf.app_name = 'playground_app'
  conf.client_id = 'playground'
  conf.logger = AppLogger
  conf.kafka_brokers = 'kafka.playground.local:9092'
  conf.schema_registry_url = 'http://schema-registry.playground.local'
end

$kafka_config = Rimless.producer.config.kafka
$rdkafka_config = Rdkafka::Config.new($kafka_config)

KafkaAdminClient = $rdkafka_config.admin

def describe_topic(name)
  return unless topic?(name)

  topics[name].merge(configs: topic_configs(name))
end

def topic_configs(name)
  KafkaAdminClient.describe_configs(
    [{ resource_type: 2, resource_name: name.to_s }]
  ).wait.resources.first.configs.map do |conf|
    [conf.name, conf.value]
  end.sort_by(&:first).to_h
end

def topic?(name)
  topics.key? name.to_s
end

def topics
  $rdkafka_config.admin.metadata.topics.index_by do |cur|
    cur[:topic_name].to_s
  end
end
