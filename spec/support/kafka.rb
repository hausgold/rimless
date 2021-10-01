# frozen_string_literal: true

# Send a single Apache Kafka message (+test+ schema).
#
# @param args [Hash{Symbol => Mixed}] additional options
def send_kafka_message(**args)
  Rimless.message(data: avro_data, topic: :test, schema: :test, **args)
end

# Send a single Apache Kafka message (+include+ schema).
def send_other_kafka_message
  Rimless.message(data: { 'id' => 'id' }, topic: :test, schema: :include)
end
