# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rimless/version'

Gem::Specification.new do |spec|
  spec.name = 'rimless'
  spec.version = Rimless::VERSION
  spec.authors = ['Hermann Mayer']
  spec.email = ['hermann.mayer92@gmail.com']

  spec.license = 'MIT'
  spec.summary = 'A bundle of opinionated Apache Kafka / Confluent ' \
                 'Schema Registry helpers.'
  spec.description = 'A bundle of opinionated Apache Kafka / Confluent ' \
                     'Schema Registry helpers.'

  base_uri = "https://github.com/hausgold/#{spec.name}"
  spec.metadata = {
    'homepage_uri' => base_uri,
    'source_code_uri' => base_uri,
    'changelog_uri' => "#{base_uri}/blob/master/CHANGELOG.md",
    'bug_tracker_uri' => "#{base_uri}/issues",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{spec.name}"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_runtime_dependency 'activesupport', '>= 5.2'
  spec.add_runtime_dependency 'avro_turf', '~> 0.11.0'
  spec.add_runtime_dependency 'karafka', '~> 1.4'
  spec.add_runtime_dependency 'karafka-sidekiq-backend', '~> 1.4'
  spec.add_runtime_dependency 'karafka-testing', '~> 1.4'
  spec.add_runtime_dependency 'sinatra', '~> 2.2'
  spec.add_runtime_dependency 'sparsify', '~> 1.1'
  spec.add_runtime_dependency 'waterdrop', '~> 1.4'
  spec.add_runtime_dependency 'webmock', '~> 3.18'
end
