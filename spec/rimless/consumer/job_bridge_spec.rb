# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer::JobBridge do
  describe '.build' do
    let(:action) do
      stub_const 'MyCustomConsumer', Class.new
      described_class.build(MyCustomConsumer)
    end

    it 'returns a Class' do
      expect(action).to be_a(Class)
    end

    it 'returns a wrapper class which inherits Rimless::Consumer::JobBridge' do
      expect(action.superclass).to be(described_class)
    end

    it 'returns a wrapper class with the given consumer configuration' do
      expect(action.consumer).to eql('MyCustomConsumer')
    end

    context 'with anonymous class' do
      let(:action) { described_class.build(Class.new) }

      it 'raises an ArgumentError' do
        expect { action }.to \
          raise_error(ArgumentError, /Anonymous consumer class passed/)
      end
    end
  end

  describe '.inspect' do
    let(:action) { class_name.inspect }

    context 'with the base class' do
      let(:class_name) { described_class }

      it 'returns the custom inspection result' do
        expect(action).to eql('Rimless::Consumer::JobBridge')
      end
    end

    context 'with an anonymous class' do
      let(:class_name) { described_class.build(MyCustomConsumer) }

      before { stub_const 'MyCustomConsumer', Class.new }

      it 'returns the custom inspection result' do
        expect(action).to \
          eql('Rimless::Consumer::JobBridge[consumer="MyCustomConsumer"]')
      end
    end
  end

  describe '#consume' do
    let(:action) { instance.consume }
    let(:instance) do
      described_class.new.tap do |consumer|
        allow(consumer).to receive(:messages).and_return(messages)
        allow(consumer).to receive(:mark_as_consumed)
      end
    end

    context 'with a single message' do
      let(:messages) { ['message'] }

      it 'calls the enqueue_job with the message as argument' do
        expect(instance).to receive(:enqueue_job).once.with('message')
        action
      end
    end

    context 'with multiple messages' do
      let(:messages) { [1, 2, 3] }

      it 'calls the enqueue_job for each message' do
        expect(instance).to receive(:enqueue_job).exactly(3).times
        action
      end
    end
  end

  describe '#enqueue_job' do
    let(:action) do
      instance.enqueue_job(kafka_message)
    end
    let(:instance) { described_class.new }
    let(:job_args) do
      { payload: 'payload', consumer: 'consumer', metadata: 'metadata' }
    end

    before do
      allow(instance).to receive(:message_to_job_args).and_return(job_args)
    end

    it 'enqueues the configured job class' do
      expect(Rimless::Consumer::Job).to \
        receive(:perform_later).once.with(**job_args)
      action
    end
  end

  describe '#message_to_job_args' do
    let(:action) { consumer.new.message_to_job_args(message) }
    let(:consumer) do
      stub_const 'MyCustomConsumer', Class.new
      described_class.build(MyCustomConsumer)
    end
    let(:message) do
      kafka_message(
        metadata: {
          topic: 'test-topic',
          partition: 67,
          offset: 7,
          timestamp: Time.current,
          received_at: Time.current,
          key: 'test-key',
          headers: { test: true }
        },
        event: 'test'
      )
    end
    let(:expected_hash) do
      {
        payload: { event: 'test' },
        consumer: 'MyCustomConsumer',
        metadata: {
          topic: 'test-topic',
          partition: 67,
          offset: 7,
          timestamp: Time.current,
          received_at: Time.current,
          key: 'test-key',
          headers: { test: true }
        }
      }
    end

    before { Timecop.freeze(2026, 2, 27, 14, 0, 0) }

    after { Timecop.return }

    it 'returns a Hash' do
      expect(action).to be_a(Hash)
    end

    it 'returns a hash with Symbol keys' do
      expect(action.keys).to all(be_a(Symbol))
    end

    it 'return the correct hash' do
      expect(action).to match(expected_hash)
    end
  end

  describe '#inspect' do
    let(:action) { instance.inspect }

    context 'with the base class' do
      let(:instance) { described_class.new }

      it 'returns the custom inspection result' do
        expect(action).to \
          eql('#<Rimless::Consumer::JobBridge consumer=nil>')
      end
    end

    context 'with an anonymous class' do
      let(:instance) { described_class.build(MyCustomConsumer).new }

      before { stub_const 'MyCustomConsumer', Class.new }

      it 'returns the custom inspection result' do
        expect(action).to \
          eql('#<Rimless::Consumer::JobBridge consumer="MyCustomConsumer">')
      end
    end
  end
end
