# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer::AvroDeserializer do
  let(:instance) { described_class.new }
  let(:params) { Karafka::Messages::Message.new(raw_payload, metadata.new) }
  let(:raw_payload) { nil }
  let(:metadata) { Karafka::Messages::Metadata }
  let(:blob) do
    Rimless.avro.encode(
      {
        'id' => 'uuid',
        'created_at' => Time.current.iso8601
      },
      schema_name: 'include_with_datetime'
    )
  end

  before do
    Timecop.freeze(2026, 4, 16, 14, 0, 0)
    reset_test_configuration!
  end

  after { Timecop.return }

  describe '#call' do
    let(:action) { instance.call(params) }

    context 'without raw payload' do
      it 'returns nil' do
        expect(action).to be_nil
      end
    end

    context 'with raw payload' do
      let(:raw_payload) { blob }

      it 'returns a hash' do
        expect(action).to be_a(Hash)
      end

      it 'returns a hash with symbol keys' do
        expect(action.keys).to all(be_a(Symbol))
      end

      it 'returns the correctly decoded hash' do
        expect(action).to eql(id: 'uuid', created_at: '2026-04-16T14:00:00Z')
      end

      context 'with datetime parsing enabled' do
        before do
          Rimless.configuration.avro_deserializer_parse_datetimes = true
        end

        it 'returns the correctly decoded hash' do
          expect(action).to eql(id: 'uuid', created_at: Time.current)
        end
      end
    end
  end

  describe '#parse_timestamps!' do
    let(:action) { instance.parse_timestamps!(obj) }

    context 'with random String' do
      let(:obj) { 'random' }

      it 'returns the original string' do
        expect(action).to be(obj)
      end
    end

    context 'with an ISO8601 date/time String (with timezone)' do
      let(:obj) { '2024-12-09T13:45:31+01:00' }

      it 'returns the parsed Time' do
        expect(action).to eql(Time.parse('2024-12-09T13:45:31+01:00'))
      end

      it 'returns the parsed time with correct timezone' do
        expect(action.zone).to eql('UTC')
      end

      it 'returns the parsed time in UTC zone' do
        expect(action.to_s).to eql('2024-12-09 12:45:31 UTC')
      end
    end

    context 'with an ISO8601 date/time String (without timezone)' do
      let(:obj) { '2024-12-09T13:45:31Z' }

      it 'returns the parsed Time' do
        expect(action).to eql(Time.parse('2024-12-09T13:45:31Z'))
      end

      it 'returns the parsed time with correct timezone' do
        expect(action.zone).to eql('UTC')
      end

      it 'returns the parsed time in UTC zone' do
        expect(action.to_s).to eql('2024-12-09 13:45:31 UTC')
      end
    end

    context 'with an ISO8601 date String' do
      let(:obj) { '2024-12-09' }

      it 'returns the parsed Time' do
        expect(action).to eql(Date.parse('2024-12-09'))
      end
    end

    context 'with Symbol' do
      let(:obj) { :random }

      it 'returns the original symbol' do
        expect(action).to be(obj)
      end
    end

    context 'with nested ISO8601 date/time String (in Hash/Array)' do
      let(:obj) { { a: { b: [{ c: '2024-12-09T13:45:31+01:00' }] } } }

      it 'returns the parsed Hash' do
        expect(action.dig(:a, :b, 0, :c)).to \
          eql(Time.parse('2024-12-09T13:45:31+01:00'))
      end
    end
  end
end
