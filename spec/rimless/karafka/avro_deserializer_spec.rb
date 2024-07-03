# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers because of various
#   testing contexts
RSpec.describe Rimless::Karafka::AvroDeserializer do
  let(:instance) { described_class.new }
  let(:params) { Karafka::Params::Params.new(raw_payload, metadata) }
  let(:raw_payload) { nil }
  let(:metadata) { Karafka::Params::Metadata }
  let(:blob) do
    Rimless.avro.encode({ 'id' => 'uuid' }, schema_name: 'include')
  end

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
        expect(action).to eql(id: 'uuid')
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
