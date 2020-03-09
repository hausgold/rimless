# frozen_string_literal: true

# The overall shared base consumer for Apache Kafka messages. Just write your
# own specific consumer and inherit this one to share logic.
class ApplicationConsumer < Rimless::BaseConsumer
end
