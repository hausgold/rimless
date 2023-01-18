# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::RSpec::Matchers do
  let(:none) { nil }
  let(:one) { send_kafka_message }
  let(:two) { 2.times.each { send_kafka_message } }
  let(:three) { 3.times.each { send_kafka_message } }

  describe '.have_sent_kafka_message' do
    context 'with schema' do
      it 'checks the Apache Avro schema (positive)' do
        expect { one }.to have_sent_kafka_message('test.test_app.test')
      end

      it 'checks the Apache Avro schema (negative)' do
        expect { one }.not_to have_sent_kafka_message('test.test_app.include')
      end

      it 'detects the expected message on different sent messages' do
        expect do
          send_kafka_message
          send_other_kafka_message
        end.to have_sent_kafka_message(:test).at_least(:once)
      end
    end

    context 'with counts' do
      it 'checks a single message was sent' do
        expect { one }.to have_sent_kafka_message.exactly(1)
      end

      it 'checks two messages were sent' do
        expect { two }.to have_sent_kafka_message.exactly(:twice)
      end

      it 'checks for at least two messages were sent' do
        expect { three }.to have_sent_kafka_message.at_least(2).times
      end

      it 'checks for at most three messages were sent' do
        expect { three }.to have_sent_kafka_message.at_most(3).times
      end
    end

    context 'with arguments' do
      it 'checks the given arguments (topic)' do
        expect { one }.to \
          have_sent_kafka_message.with(topic: 'test.test-app.test')
      end

      it 'checks the given arguments (key)' do
        expect { send_kafka_message(key: 'test-key') }.to \
          have_sent_kafka_message.with(key: 'test-key', topic: String)
      end

      it 'checks the given arguments (topic and key)' do
        expect { send_kafka_message(key: 'test-key') }.to \
          have_sent_kafka_message.with(key: 'test-key',
                                       topic: 'test.test-app.test')
      end

      it 'checks the given arguments (topic and key) on multiple messages' do
        expect do
          send_kafka_message(key: 'test-key')
          one
        end.to have_sent_kafka_message.with(key: 'test-key',
                                            topic: 'test.test-app.test')
      end
    end

    context 'with data' do
      it 'checks the given data (name)' do
        expect { one }.to have_sent_kafka_message.with_data(name: 'test')
      end

      it 'checks the given data (name, negative)' do
        expect { one }.not_to have_sent_kafka_message.with_data(unknown: true)
      end

      it 'checks the given data (name, id)' do
        expect { one }.to \
          have_sent_kafka_message.with_data(name: 'test',
                                            include: { id: 'uuid-v4' })
      end
    end

    context 'with mix and match' do
      let(:many) do
        two
        send_kafka_message(key: 'test-key')
        send_kafka_message(key: 'test-key')
        send_other_kafka_message
        one
      end

      it 'checks for a complex expectation among a single message' do
        expect { one }.to have_sent_kafka_message('test.test_app.test')
          .with(topic: 'test.test-app.test').with_data(name: 'test')
          .at_least(:once)
      end

      it 'checks for a complex expectation among many messages' do
        expect { many }.to have_sent_kafka_message('test.test_app.test')
          .with(key: 'test-key', topic: 'test.test-app.test').twice
          .with_data(name: 'test').twice
      end
    end

    it 'checks no message was sent' do
      expect { none }.not_to have_sent_kafka_message
    end
  end
end
