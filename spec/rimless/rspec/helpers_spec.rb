# frozen_string_literal: true

RSpec.describe Rimless::RSpec::Helpers do
  let(:instance) { Class.new { include Rimless::RSpec::Helpers } }

  describe '#avro_parse' do
    let(:encoded) { Rimless.avro.encode(avro_data, schema_name: 'test') }

    it 'decodes a binary Apache Avro message' do
      expect(avro_parse(encoded)).to be_eql(avro_data_symbol_keys)
    end
  end
end
