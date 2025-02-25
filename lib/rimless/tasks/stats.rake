# frozen_string_literal: true

if defined?(Rails) && Rails.env.development?
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
