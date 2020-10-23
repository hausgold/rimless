# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rimless/version'

Gem::Specification.new do |spec|
  spec.name          = 'rimless'
  spec.version       = Rimless::VERSION
  spec.authors       = ['Hermann Mayer']
  spec.email         = ['hermann.mayer92@gmail.com']

  spec.summary       = 'A bundle of opinionated Apache Kafka / Confluent ' \
                       'Schema Registry helpers.'
  spec.description   = 'A bundle of opinionated Apache Kafka / Confluent ' \
                       'Schema Registry helpers.'
  spec.homepage      = 'https://github.com/hausgold/rimless'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '>= 4.2.0'
  spec.add_runtime_dependency 'avro_turf', '~> 0.11.0'
  spec.add_runtime_dependency 'karafka', '~> 1.4'
  spec.add_runtime_dependency 'karafka-sidekiq-backend', '~> 1.4'
  spec.add_runtime_dependency 'karafka-testing', '~> 1.4'
  spec.add_runtime_dependency 'sinatra'
  spec.add_runtime_dependency 'sparsify', '~> 1.1'
  spec.add_runtime_dependency 'waterdrop', '~> 1.2'
  spec.add_runtime_dependency 'webmock'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler', '>= 1.16', '< 3'
  spec.add_development_dependency 'factory_bot', '~> 4.11'
  spec.add_development_dependency 'railties', '>= 4.2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rdoc', '~> 6.1'
  spec.add_development_dependency 'redcarpet', '~> 3.4'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.63.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.31'
  spec.add_development_dependency 'simplecov', '~> 0.15'
  spec.add_development_dependency 'timecop', '~> 0.9.1'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.9.18'
  spec.add_development_dependency 'yard-activesupport-concern', '~> 0.0.1'
end
