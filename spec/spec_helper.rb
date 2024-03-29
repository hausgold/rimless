# frozen_string_literal: true

require 'simplecov'
SimpleCov.command_name 'specs'

require 'bundler/setup'
require 'rimless'
require 'timecop'

# Load all support helpers and shared examples
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Enable the focus inclusion filter and run all when no filter is set
  # See: http://bit.ly/2TVkcIh
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clear and recreate the tmp directory before each test case
  config.before do
    FileUtils.rm_rf(tmp_path)
    FileUtils.mkdir_p(tmp_path)
  end

  # Clear the test configuration before we begin
  config.before do
    reset_test_configuration!
  end
end

require 'rimless/rspec'
