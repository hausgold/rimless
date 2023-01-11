# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'countless/rake_tasks'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

# Configure all code statistics directories
Countless.configure do |config|
  config.stats_base_directories = [
    { name: 'Top-levels', dir: 'lib',
      pattern: %r{/lib(/rimless)?/[^/]+\.rb$} },
    { name: 'Top-levels specs', test: true, dir: 'spec',
      pattern: %r{/spec(/rimless)?/[^/]+_spec\.rb$} },
    { name: 'RSpec matchers', pattern: 'lib/rimless/rspec/**/*.rb' },
    { name: 'RSpec matchers specs', test: true,
      pattern: 'spec/rimless/rspec/**/*_spec.rb' },
    { name: 'Rake Tasks', pattern: 'lib/rimless/tasks/**/*' },
    { name: 'Karafka Extensions', pattern: 'lib/rimless/karafka/**/*.rb' }
  ]
end
