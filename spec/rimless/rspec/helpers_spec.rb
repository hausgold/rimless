# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::RSpec::Helpers do
  let(:instance) { Class.new { include Rimless::RSpec::Helpers } }

  describe '#avro_parse' do
    let(:encoded) { Rimless.avro.encode(avro_data, schema_name: 'test') }

    it 'decodes a binary Apache Avro message' do
      expect(avro_parse(encoded)).to be_eql(avro_data_symbol_keys)
    end
  end

  describe '#kafka_message' do
    context 'with string topic' do
      let(:action) { kafka_message(topic: 'test_topic') }

      # rubocop:disable Style/OpenStructUse because we want to test
      #   the interface explicitly
      it 'returns a OpenStruct' do
        expect(action).to be_a(OpenStruct)
      end
      # rubocop:enable Style/OpenStructUse

      it 'sets the full topic' do
        expect(action.topic).to be_eql('test.test-app.test-topic')
      end
    end

    context 'with topic hash' do
      let(:action) { kafka_message(topic: { app: 'foo', name: :bar }) }

      it 'sets the full topic' do
        expect(action.topic).to be_eql('test.foo.bar')
      end
    end

    context 'with payload' do
      let(:action) { kafka_message(topic: :foo, foo: { bar: true }) }

      it 'sets the full topic' do
        expect(action.payload).to be_eql(foo: { bar: true })
      end
    end

    context 'without payload' do
      let(:action) { kafka_message(topic: :foo) }

      it 'sets the full topic' do
        expect(action.payload).to be_eql({})
      end
    end

    context 'with headers' do
      let(:action) { kafka_message(topic: :foo, headers: { foo: true }) }

      it 'sets the full topic' do
        expect(action.headers).to be_eql(foo: true)
      end
    end

    context 'without headers' do
      let(:action) { kafka_message(topic: :foo) }

      it 'sets the full topic' do
        expect(action.headers).to be_eql({})
      end
    end
  end

  describe '#capture_kafka_messages' do
    context 'without captured messages' do
      it 'returns an empty array' do
        messages = capture_kafka_messages { nil }
        expect(messages).to match([])
      end
    end

    context 'with a single captured message' do
      let(:action) { capture_kafka_messages { send_kafka_message } }

      it 'returns an array with a single messages' do
        expect(action).to match([Hash])
      end

      it 'returns a message with the correct arguments' do
        expect(action.first).to \
          match(a_hash_including(args: { topic: 'test.test-app.test' }))
      end

      it 'returns a message with correct type' do
        expect(action.first).to match(a_hash_including(type: :sync))
      end

      it 'returns a message with the Apache Avro encoded data (blob)' do
        expect(action.first).to match(a_hash_including(encoded_data: String))
      end

      it 'returns a message with the parsed data' do
        expect(action.first[:data]).to \
          match('name' => 'test',
                'include' => { 'id' => 'uuid-v4' },
                'deep' => { 'test' => 'true', 'fancy' => 'data' })
      end
    end

    context 'with multiple captured message' do
      let(:action) do
        capture_kafka_messages do
          send_kafka_message
          send_other_kafka_message
        end
      end

      it 'returns an array of two messages' do
        expect(action).to match([Hash, Hash])
      end
    end
  end
end
