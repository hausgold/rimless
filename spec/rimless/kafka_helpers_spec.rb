# frozen_string_literal: true

RSpec.describe Rimless::KafkaHelpers do
  let(:described_class) { Rimless }
  let(:method) { nil }
  let(:args) { {} }
  let(:action) { described_class.send(method, **args) }

  describe '.topic' do
    it 'produces the correct topic name (app fallback)' do
      expect(described_class.topic(:name)).to be_eql('test.test-app.name')
    end

    it 'produces the correct topic name (app set)' do
      expect(described_class.topic(:name, app: :app)).to \
        be_eql('test.app.name')
    end

    it 'produces the correct topic name (string name)' do
      expect(described_class.topic('name')).to be_eql('test.test-app.name')
    end

    it 'produces the correct topic name (mix and match)' do
      expect(described_class.topic(name: 'app', app: :test)).to \
        be_eql('test.test.app')
    end
  end

  describe '.sync_message' do
    let(:method) { :sync_message }
    let(:args) do
      { data: avro_data, schema: :test, topic: :test, additional: true }
    end

    it 'calls the sync_raw_message method' do
      expect(described_class).to receive(:sync_raw_message).once
      action
    end

    it 'calls the sync_raw_message method with correct args' do
      expect(described_class).to receive(:sync_raw_message)
        .with(data: String, topic: :test, additional: true)
      action
    end
  end

  describe '.async_message' do
    let(:method) { :async_message }
    let(:args) do
      { data: avro_data, schema: :test, topic: :test, additional: true }
    end

    it 'calls the async_raw_message method' do
      expect(described_class).to receive(:async_raw_message).once
      action
    end

    it 'calls the sync_raw_message method with correct args' do
      expect(described_class).to receive(:async_raw_message)
        .with(data: String, topic: :test, additional: true)
      action
    end
  end

  describe '.sync_raw_message' do
    let(:method) { :sync_raw_message }
    let(:args) { { data: 'data', topic: :test, additional: true } }

    it 'passes the correct arguments to WaterDrop' do
      expect(WaterDrop::SyncProducer).to receive(:call)
        .with('data', topic: 'test.test-app.test', additional: true)
      action
    end
  end

  describe '.async_raw_message' do
    let(:method) { :async_raw_message }
    let(:args) { { data: 'data', topic: :test, additional: true } }

    it 'passes the correct arguments to WaterDrop' do
      expect(WaterDrop::AsyncProducer).to receive(:call)
        .with('data', topic: 'test.test-app.test', additional: true)
      action
    end
  end
end
