# frozen_string_literal: true

require 'active_support'
require 'active_support/concern'
require 'active_support/configurable'
require 'active_support/time'
require 'active_support/time_with_zone'
require 'active_support/core_ext/object'
require 'active_support/core_ext/module'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'waterdrop'
require 'avro_turf/messaging'
require 'karafka'
require 'karafka-sidekiq-backend'
require 'sparsify'
require 'erb'
require 'pp'

# The top level namespace for the rimless gem.
module Rimless
  # Top level elements
  autoload :Configuration, 'rimless/configuration'
  autoload :ConfigurationHandling, 'rimless/configuration_handling'
  autoload :AvroHelpers, 'rimless/avro_helpers'
  autoload :AvroUtils, 'rimless/avro_utils'
  autoload :KafkaHelpers, 'rimless/kafka_helpers'
  autoload :Dependencies, 'rimless/dependencies'
  autoload :BaseConsumer, 'rimless/base_consumer'
  autoload :Consumer, 'rimless/consumer'
  autoload :ConsumerJob, 'rimless/consumer_job'

  # All Karafka-framework related components
  module Karafka
    autoload :Base64Interchanger, 'rimless/karafka/base64_interchanger'
    autoload :PassthroughMapper, 'rimless/karafka/passthrough_mapper'
    autoload :AvroDeserializer, 'rimless/karafka/avro_deserializer'
  end

  # Load standalone code
  require 'rimless/version'
  require 'rimless/railtie' if defined? Rails

  # Include top-level features
  include Rimless::ConfigurationHandling
  include Rimless::AvroHelpers
  include Rimless::KafkaHelpers
  include Rimless::Dependencies
  include Rimless::Consumer
end
