# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Extensions::KafkaHelpers do
  let(:described_class) { Rimless }

  describe '.topic' do
    it 'produces the correct topic name (app fallback)' do
      expect(described_class.topic(:name)).to eql('test.test-app.name')
    end

    it 'produces the correct topic name (app set)' do
      expect(described_class.topic(:name, app: :app)).to \
        eql('test.app.name')
    end

    it 'produces the correct topic name (string name)' do
      expect(described_class.topic('name')).to eql('test.test-app.name')
    end

    it 'produces the correct topic name (mix and match)' do
      expect(described_class.topic(name: 'app', app: :test)).to \
        eql('test.test.app')
    end

    it 'produces the correct topic name with kebab-cased symbols' do
      expect(described_class.topic(name: :new_customers, app: :test_api)).to \
        eql('test.test-api.new-customers')
    end

    it 'returns the full name when given' do
      expect(described_class.topic(full_name: 'my.custom.topic')).to \
        eql('my.custom.topic')
    end
  end
end
