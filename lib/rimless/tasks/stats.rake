# frozen_string_literal: true

# TODO: Remove this file, when Rails >= 8.0 is the minimum requirement
if defined?(Rails) && Rails.env.development? && Rails::VERSION::STRING < '8.0.0'
  require 'rspec/core/rake_task'

  # rubocop:disable Rails/RakeEnvironment -- because this is just an helper
  #   command, no need for an application bootstrap
  task :stats do
    require 'rails/code_statistics'

    [
      [:unshift, 'Consumer', 'app/consumers']
    ].each do |method, type, dir|
      next unless File.directory? dir

      STATS_DIRECTORIES.send(method, [type, dir])
      CodeStatistics::TEST_TYPES << type if type.include? 'specs'
    end
  end
  # rubocop:enable Rails/RakeEnvironment
end
