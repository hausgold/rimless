# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Extensions::Producer do
  let(:described_class) { Rimless }
  let(:action) { described_class.send(method, **args) }

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
    let(:args) { { data: 'data', topic: :test, partition: 1 } }

    it 'passes the correct arguments to WaterDrop' do
      expect(Rimless.producer).to receive(:produce_sync)
        .with(payload: 'data', topic: 'test.test-app.test', partition: 1)
      action
    end

    context 'with Symbol-keyed headers hash' do
      let(:args) { { data: 'data', topic: :test, headers: { test: true } } }

      it 'passes the correct arguments to WaterDrop' do
        expect(Rimless.producer).to receive(:produce_sync)
          .with(payload: 'data', topic: 'test.test-app.test',
                headers: { 'test' => 'true' })
        action
      end
    end
  end

  describe '.async_raw_message' do
    let(:method) { :async_raw_message }
    let(:args) { { data: 'data', topic: :test, partition: 1 } }

    it 'passes the correct arguments to WaterDrop' do
      expect(Rimless.producer).to receive(:produce_async)
        .with(payload: 'data', topic: 'test.test-app.test', partition: 1)
      action
    end

    context 'with Symbol-keyed headers hash' do
      let(:args) { { data: 'data', topic: :test, headers: { test: true } } }

      it 'passes the correct arguments to WaterDrop' do
        expect(Rimless.producer).to receive(:produce_async)
          .with(payload: 'data', topic: 'test.test-app.test',
                headers: { 'test' => 'true' })
        action
      end
    end
  end
end
