# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::ConfigurationHandling do
  let(:described_class) { Rimless }

  before { reset_test_configuration! }

  it 'allows the access of the configuration' do
    expect(described_class.configuration).not_to be_nil
  end

  describe '.configure' do
    it 'yields the configuration' do
      expect do |block|
        described_class.configure(&block)
      end.to yield_with_args(described_class.configuration)
    end
  end

  describe '.reset_configuration!' do
    it 'resets the configuration to its defaults' do
      described_class.configuration.env = 'production'
      expect { described_class.reset_configuration! }.to \
        change { described_class.configuration.env }
    end
  end

  describe '.env' do
    it 'reads the configuration env' do
      described_class.configuration.env = 'local'
      expect(described_class.env).to be_eql('local')
    end

    it 'allows inquirer access' do
      described_class.configuration.env = 'production'
      expect(described_class.env.production?).to be(true)
    end
  end

  describe '.local_app_name' do
    context 'without Rails available' do
      it 'returns nil' do
        expect(described_class.local_app_name).to be_nil
      end
    end

    context 'without Rails application available' do
      # rubocop:disable RSpec/VerifiedDoubles because we do not have a
      #   Rails constant around (rails not loaded)
      before { stub_const('Rails', double('Rails', application: nil)) }
      # rubocop:enable RSpec/VerifiedDoubles

      it 'returns nil' do
        expect(described_class.local_app_name).to be_nil
      end
    end

    context 'with Rails application available' do
      before { add_fake_rails_app('IdentityApi') }

      after { remove_fake_rails_app('IdentityApi') }

      it 'returns the application name' do
        expect(described_class.local_app_name).to be_eql('identity-api')
      end
    end
  end

  describe '.topic_prefix' do
    context 'with specific app' do
      it 'sets the app correctly' do
        expect(described_class.topic_prefix('fancy-app')).to \
          end_with('.fancy-app.')
      end

      it 'returns the expected string' do
        expect(described_class.topic_prefix('fancy-app')).to \
          end_with('test.fancy-app.')
      end
    end

    context 'without specific app' do
      it 'returns the expected string' do
        expect(described_class.topic_prefix).to \
          end_with('test.test-app.')
      end
    end
  end
end
