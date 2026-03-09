# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer::App do
  let(:instance) { described_class.new }

  describe '#initialize' do
    let(:action) { described_class.new }
    let(:config) { described_class.config }

    it "configures the kafka 'client.id' setting" do
      action
      expect(config.kafka[:'client.id']).to \
        be(Rimless.configuration.client_id)
    end

    it "configures the kafka 'bootstrap.servers' setting" do
      action
      expect(config.kafka[:'bootstrap.servers']).to \
        be(Rimless.configuration.kafka_brokers)
    end

    it "configures the kafka 'request.required.acks' setting" do
      action
      expect(config.kafka[:'request.required.acks']).to be(-1)
    end

    it 'configures the client identitifer' do
      action
      expect(config.client_id).to \
        match(/^#{Rimless.configuration.client_id}-\d+-.*/)
    end

    it 'configures the consumer group identitifer' do
      action
      expect(config.group_id).to be(Rimless.configuration.client_id)
    end

    it 'configures the non-strict topic namespacing' do
      action
      expect(config.strict_topics_namespacing).to be(false)
    end

    it 'configures the shutdown timeout' do
      action
      expect(config.shutdown_timeout).to eql(10.seconds.in_milliseconds)
    end

    describe 'consumer persistence' do
      context 'when Rimless environment is production' do
        before { Rimless.configuration.env = :production }

        it 'enables the consumer persistence' do
          action
          expect(config.consumer_persistence).to be(true)
        end
      end

      context 'when Rimless environment is development' do
        before { Rimless.configuration.env = :development }

        it 'disables the consumer persistence' do
          action
          expect(config.consumer_persistence).to be(false)
        end
      end
    end

    it 'configures the logger' do
      action
      expect(config.logger).to be(Rimless.logger)
    end

    describe 'logger listener' do
      let(:listeners) { [] }

      before do
        allow(Karafka.monitor).to \
          receive(:subscribe) { |arg, *| listeners << arg if arg }
      end

      context 'with default configuration' do
        it 'configures the logger listener' do
          action
          expect(listeners).to \
            include(Rimless.configuration.consumer_logger_listener)
        end
      end

      context 'with nil as logger listener' do
        before { Rimless.configuration.consumer_logger_listener = nil }

        it 'does not configure the logger listener' do
          action
          expect(listeners).not_to \
            include(Rimless.configuration.consumer_logger_listener)
        end
      end
    end

    context 'with user configuration block' do
      before do
        Rimless.configuration.consumer_configure = proc do |config|
          config.kafka[:'request.required.acks'] = 0
        end
      end

      it 'calls the consumer_configure configuration' do
        action
        expect(config.kafka).to include('request.required.acks': 0)
      end
    end
  end

  describe '#topics' do
    let(:topics) { instance.routes.first.topics }

    before do
      instance.routes.clear
      stub_const 'MyCustomConsumer', Class.new
    end

    context 'with topics, without block' do
      before do
        instance.topics(topic1: MyCustomConsumer,
                        topic2: MyCustomConsumer)
      end

      it 'configures a single consumer group' do
        expect(Rimless.consumer.routes.count).to be(1)
      end

      it 'configures the correct consumer group name' do
        expect(Rimless.consumer.routes.first.name).to \
          eql('test-app')
      end

      it 'configures two topics' do
        expect(topics.count).to be(2)
      end

      it 'configures the first topic name correctly' do
        expect(topics.first.name).to eql('test.test-app.topic1')
      end

      it 'configures the first topic consumer correctly (superclass)' do
        expect(topics.first.consumer.superclass).to \
          be(Rimless::Consumer::JobBridge)
      end

      it 'configures the first topic consumer correctly (inspect)' do
        expect(topics.first.consumer.inspect).to \
          eql('Rimless::Consumer::JobBridge[consumer="MyCustomConsumer"]')
      end

      it 'configures the first topic payload deserializer correctly' do
        expect(topics.first.deserializers.payload).to \
          be_a(Rimless::Consumer::AvroDeserializer)
      end

      it 'configures the first topic key deserializer correctly (default)' do
        expect(topics.first.deserializers.key).to \
          be_a(Karafka::Deserializers::Key)
      end

      it 'configures the first topic headers deserializer ' \
         'correctly (default)' do
        expect(topics.first.deserializers.headers).to \
          be_a(Karafka::Deserializers::Headers)
      end

      it 'configures the second topic name correctly' do
        expect(topics.last.name).to eql('test.test-app.topic2')
      end

      it 'configures the second topic consumer correctly (superclass)' do
        expect(topics.last.consumer.superclass).to \
          be(Rimless::Consumer::JobBridge)
      end

      it 'configures the second topic consumer correctly (inspect)' do
        expect(topics.last.consumer.inspect).to \
          eql('Rimless::Consumer::JobBridge[consumer="MyCustomConsumer"]')
      end

      it 'configures the second topic payload deserializer correctly' do
        expect(topics.last.deserializers.payload).to \
          be_a(Rimless::Consumer::AvroDeserializer)
      end

      it 'configures the second topic key deserializer correctly (default)' do
        expect(topics.last.deserializers.key).to \
          be_a(Karafka::Deserializers::Key)
      end

      it 'configures the second topic headers deserializer ' \
         'correctly (default)' do
        expect(topics.last.deserializers.headers).to \
          be_a(Karafka::Deserializers::Headers)
      end
    end

    context 'without topics, but a block' do
      before do
        instance.topics do
          topic('my.custom.topic') do
            consumer MyCustomConsumer
          end
        end
      end

      it 'configures the topic name correctly' do
        expect(topics.last.name).to eql('my.custom.topic')
      end

      it 'configures the topic consumer correctly' do
        expect(topics.last.consumer).to be(MyCustomConsumer)
      end

      it 'configures the topic payload deserializer correctly (default)' do
        expect(topics.last.deserializers.payload).to \
          be_a(Karafka::Deserializers::Payload)
      end

      it 'configures the topic key deserializer correctly (default)' do
        expect(topics.last.deserializers.key).to \
          be_a(Karafka::Deserializers::Key)
      end

      it 'configures the topic headers deserializer correctly (default)' do
        expect(topics.last.deserializers.headers).to \
          be_a(Karafka::Deserializers::Headers)
      end
    end
  end

  describe '#topic_names' do
    let(:action) { instance.topic_names(parts) }

    context 'with a string' do
      let(:parts) { 'admins' }

      it 'returns an array with correct elements' do
        expect(action).to eql(%w[test.test-app.admins])
      end
    end

    context 'with a symbol' do
      let(:parts) { :admins }

      it 'returns an array with correct elements' do
        expect(action).to eql(%w[test.test-app.admins])
      end
    end

    context 'with a hash, with single name' do
      let(:parts) { { app: :test_api, name: :admins } }

      it 'returns an array with correct elements' do
        expect(action).to eql(%w[test.test-api.admins])
      end
    end

    context 'with a hash, with multiple names' do
      let(:parts) { { app: :test_api, names: %i[customers admins] } }

      it 'returns an array with correct elements' do
        expect(action).to \
          eql(%w[test.test-api.customers test.test-api.admins])
      end
    end
  end

  describe '#configure' do
    let(:action) do
      instance.configure do |config|
        config.kafka[:'auto.offset.reset'] = 'beginning'
        config.kafka[:'enable.auto.commit'] = false
      end
    end

    it 'allows to configure ruby-kafka settings' do
      expect { action }.to \
        change { described_class.config.kafka[:'enable.auto.commit'] }
        .from(nil).to(false)
    end
  end
end
