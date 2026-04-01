# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer::Base do
  let(:instance) { described_class.new }
  let(:message) do
    kafka_message(event: 'user_created',
                  test: true,
                  email: 'test@example.com')
  end

  describe '.build_for_job' do
    let(:action) { described_class.build_for_job(payload:, metadata:) }
    let(:payload) do
      { event: 'user_created', test: true, email: 'test@example.com' }
    end
    let(:metadata) do
      {
        'topic' => 'test-topic',
        'partition' => 67,
        'offset' => 7,
        'timestamp' => Time.current,
        'received_at' => Time.current,
        'key' => 'test-key',
        'headers' => { 'test' => true }
      }
    end

    before { Timecop.freeze(2026, 2, 27, 14, 0, 0) }

    after { Timecop.return }

    it 'returns a new instance of itself' do
      expect(action).to be_a(described_class)
    end

    it 'configures a fake coordinator' do
      expect(action.coordinator).to \
        be_a(described_class::JobContextCoordinator)
    end

    it 'configures a fake coordinator with topic' do
      expect(action.coordinator.topic).to eql('test-topic')
    end

    it 'configures a fake coordinator with partition' do
      expect(action.coordinator.partition).to be(67)
    end

    it 'configures a producer' do
      expect(action.producer).to be(Rimless.producer)
    end

    it 'injects the built message' do
      expect(action.messages.first).to be_a(Karafka::Messages::Message)
    end

    it 'allows to access the already deserialized payload on the message' do
      expect(action.messages.first.payload).to be(payload)
    end

    it 'allows to access the already deserialized key on the message' do
      expect(action.messages.first.key).to be(metadata['key'])
    end

    it 'allows to access the already deserialized headers on the message' do
      expect(action.messages.first.headers).to be(metadata['headers'])
    end

    it 'allows to access the metadata on the message' do
      expect(action.messages.first.metadata).to \
        be_a(Karafka::Messages::Metadata)
    end

    describe '#consume' do
      let(:action) { instance.consume }
      let(:instance) { described_class.build_for_job(payload:, metadata:) }

      it 'returns the correct arguments' do
        expect(instance).to \
          receive(:user_created).with(test: true, email: 'test@example.com')
        action
      end

      it 'makes the current message accessible' do
        expect { action }.to \
          change(instance, :message)
          .from(nil)
          .to(instance.messages.first)
      end
    end

    describe '#arguments' do
      let(:action) { instance.arguments }
      let(:instance) { described_class.build_for_job(payload:, metadata:) }

      before { instance.message = instance.messages.first }

      it 'returns the correct arguments' do
        expect(action).to match(test: true, email: 'test@example.com')
      end
    end

    describe '#event' do
      let(:action) { instance.event }
      let(:instance) { described_class.build_for_job(payload:, metadata:) }

      before { instance.message = instance.messages.first }

      it 'returns the correct event name' do
        expect(action).to be(:user_created)
      end
    end
  end

  describe '.job_deserializers' do
    let(:action) { described_class.job_deserializers }

    it 'returns a Karafka::Routing::Features::Deserializers::Config' do
      expect(action).to be_a(Karafka::Routing::Features::Deserializers::Config)
    end

    # rubocop:disable RSpec/IdenticalEqualityAssertion -- because we
    #   check for memoization here
    it 'memoizes the result' do
      expect(described_class.job_deserializers).to \
        be(described_class.job_deserializers)
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion

    it 'configures a passthrough payload deserializer' do
      raw = 'value'
      metadata = Karafka::Messages::Metadata.new
      message = Karafka::Messages::Message.new(raw, metadata)
      expect(action.payload.call(message)).to be(raw)
    end

    it 'configures a passthrough key deserializer' do
      raw = 'value'
      metadata = Karafka::Messages::Metadata.new(raw_key: raw)
      message = Karafka::Messages::Message.new(raw, metadata)
      expect(action.key.call(message)).to be(raw)
    end

    it 'configures a passthrough headers deserializer' do
      raw = 'value'
      metadata = Karafka::Messages::Metadata.new(raw_headers: raw)
      message = Karafka::Messages::Message.new(raw, metadata)
      expect(action.headers.call(message)).to be(raw)
    end
  end

  describe '#consume' do
    let(:action) { instance.consume }

    before { instance.messages = [message] }

    it 'makes the current message accessible' do
      expect { action }.to \
        change(instance, :message)
        .from(nil)
        .to(message)
    end

    it 'calls the event method with correct arguments' do
      expect(instance).to \
        receive(:user_created).with(test: true, email: 'test@example.com')
      action
    end

    it 'does not raise error when event is nil' do
      allow(instance).to receive(:event).and_return(nil)
      expect { action }.not_to raise_error
    end
  end

  describe '#arguments' do
    let(:action) { instance.arguments }

    before { instance.message = message }

    context 'with Symbol keys' do
      it 'returns the correct arguments' do
        expect(action).to match(test: true, email: 'test@example.com')
      end
    end

    context 'with String keys' do
      let(:message) do
        kafka_message('event' => 'user_created',
                      'test' => true,
                      'email' => 'test@example.com')
      end

      it 'returns the correct event name' do
        expect(action).to match('test' => true, 'email' => 'test@example.com')
      end
    end
  end

  describe '#event' do
    let(:action) { instance.event }

    before { instance.message = message }

    context 'with Symbol keys' do
      it 'returns the correct event name' do
        expect(action).to be(:user_created)
      end
    end

    context 'with String keys' do
      let(:message) do
        kafka_message('event' => 'user_created',
                      'test' => true,
                      'email' => 'test@example.com')
      end

      it 'returns the correct event name' do
        expect(action).to be(:user_created)
      end
    end

    context 'with missing event key' do
      let(:message) { kafka_message('test' => true) }

      it 'returns nil' do
        expect(action).to be_nil
      end
    end
  end
end
