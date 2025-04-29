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
  #
  # rubocop:disable RSpec/RemoveConst -- because of the Rails constant cleanup
  config.before do
    # Since Sidekiq >=8.0.3, the +railties+ gem is required (see
    # https://bit.ly/4m9DCmj), which defines the +Rails+ constant, but we do
    # not ship a Rails dummy application here, so this causes issues on the
    # Rimless gem configuration as we check if the +Rails+ constant is defined,
    # and if so we try to access details like +Rails.root+ which is then not
    # initialized. Therefore, we just clear the environment before each test.
    Object.send(:remove_const, :Rails) if defined? Rails

    reset_test_configuration!
  end
  # rubocop:enable RSpec/RemoveConst
end

require 'rimless/rspec'
