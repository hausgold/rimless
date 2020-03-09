# frozen_string_literal: true

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

      it 'returns a OpenStruct' do
        expect(action).to be_a(OpenStruct)
      end

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
end
