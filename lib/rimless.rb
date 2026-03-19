# frozen_string_literal: true

require 'zeitwerk'
require 'logger'
require 'erb'
require 'active_support'
require 'active_support/concern'
require 'active_support/configurable'
require 'active_support/time'
require 'active_support/time_with_zone'
require 'active_support/core_ext/object'
require 'active_support/core_ext/module'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_job'
require 'retries'
require 'sparsify'
require 'avro_turf/messaging'
require 'waterdrop'
require 'karafka'

# The top level namespace for the rimless gem.
module Rimless
  # Configure the relative gem code base location
  root_path = Pathname.new("#{__dir__}/rimless")

  # Setup a Zeitwerk autoloader instance and configure it
  loader = Zeitwerk::Loader.for_gem

  # Do not auto load some parts of the gem
  loader.ignore(root_path.join('compatibility*'))
  loader.ignore(root_path.join('initializers*'))
  loader.ignore(root_path.join('tasks*'))
  loader.ignore(root_path.join('railtie.rb'))
  loader.ignore(root_path.join('rspec*'))
  loader.do_not_eager_load(root_path.join('configuration.rb'))
  loader.do_not_eager_load(root_path.join('consumer/job.rb'))

  # Finish the auto loader configuration
  loader.setup

  # Load standalone code
  require 'rimless/version'
  require 'rimless/railtie' if defined? Rails

  # Load all initializers of the gem
  Dir[root_path.join('initializers/**/*.rb')].each { |path| require path }

  # Include top-level features
  include Extensions::ConfigurationHandling
  include Extensions::Dependencies
  include Extensions::AvroHelpers
  include Extensions::KafkaHelpers
  include Extensions::Producer
  include Extensions::Consumer

  # Make sure to eager load all constants
  loader.eager_load
end
