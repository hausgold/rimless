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
    { name: 'Initializers', pattern: 'lib/rimless/initializers/**/*.rb' },
    { name: 'Compatibilities', pattern: 'lib/rimless/compatibility/**/*.rb' },
    { name: 'Compatibilities specs', test: true,
      pattern: 'spec/rimless/compatibility/**/*_spec.rb' },
    { name: 'Consumer', pattern: 'lib/rimless/consumer/**/*.rb' },
    { name: 'Consumer specs', test: true,
      pattern: 'spec/rimless/consumer/**/*_spec.rb' },
    { name: 'Extensions', pattern: 'lib/rimless/extensions/**/*.rb' },
    { name: 'Extensions specs', test: true,
      pattern: 'spec/rimless/extensions/**/*_spec.rb' },
    { name: 'RSpec extensions', pattern: 'lib/rimless/rspec/**/*.rb' },
    { name: 'RSpec extensions specs', test: true,
      pattern: 'spec/rimless/rspec/**/*_spec.rb' },
    { name: 'Rake Tasks', pattern: 'lib/rimless/tasks/**/*' }
  ]
end
