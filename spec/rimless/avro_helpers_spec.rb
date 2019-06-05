# frozen_string_literal: true

RSpec.describe Rimless::AvroHelpers do
  let(:described_class) { Rimless }

  describe '.avro_decode' do
    let(:blob) do
      Rimless.avro.encode({ 'id' => 'uuid' }, schema_name: 'include')
    end

    it 'decodes a binary blob' do
      expect(described_class.avro_decode(blob)).to be_eql(id: 'uuid')
    end
  end

  describe '.avro_encode' do
    let(:include_data) { { id: 'uuid' } }
    let(:schema_data) { { name: 'test' } }

    it 'sanitizes the input data' do
      expect(described_class).to \
        receive(:avro_sanitize).with(include_data).once.and_call_original
      described_class.avro_encode(include_data, schema: 'include')
    end

    it 'sanitizes symbol schema names' do
      expect(described_class.avro).to \
        receive(:encode).with(anything, schema_name: 'include').once
      described_class.avro_encode(include_data, schema: :include)
    end

    context 'with absolute schema name' do
      let(:schema) { 'test.test_app.include' }

      it 'keeps the schema name' do
        expect(described_class.avro).to \
          receive(:encode).with(anything, schema_name: schema).once
        described_class.avro_encode(include_data, schema: schema)
      end
    end

    context 'with flat relative schema name' do
      let(:schema) { 'include' }

      it 'keeps the schema name' do
        expect(described_class.avro).to \
          receive(:encode).with(anything, schema_name: schema).once
        described_class.avro_encode(include_data, schema: schema)
      end
    end

    context 'with deep relative schema name' do
      let(:schema) { '.deep.schema' }

      it 'resolves the relative schema name' do
        expect(described_class.avro).to \
          receive(:encode).with(anything,
                                schema_name: 'test.test_app.deep.schema').once
        described_class.avro_encode(schema_data, schema: schema)
      end
    end
  end

  describe '.avro_schemaless_h' do
    let(:deep) { { a: { b: { c: { bool: true, int: 1, str: 'test' } } } } }
    let(:flat) do
      {
        'a.b.c.bool' => 'true',
        'a.b.c.int' => '1',
        'a.b.c.str' => 'test'
      }
    end

    it 'converts the deep hash to a flat sanitized one' do
      expect(described_class.avro_schemaless_h(deep)).to be_eql(flat)
    end

    it 'keeps flat hashes untouched' do
      expect(described_class.avro_schemaless_h(flat)).to be_eql(flat)
    end
  end

  describe '.avro_to_h' do
    let(:complex_class) do
      Class.new(OpenStruct) do
        def as_json(_options = nil)
          to_h
        end
      end
    end
    let(:user) do
      {
        'id' => '8d8b9d90-d702-495a-8c10-88eecb508d9d',
        'email' => 'brad_sanford2@weimann.us',
        'type' => 'employee',
        'status' => 'active',
        'created_at' => '2019-02-28T10:18:45Z',
        'updated_at' => '2019-02-28T10:18:45Z',
        'confirmed_at' => nil,
        'locked_at' => nil,
        'recovery_at' => nil
      }
    end
    let(:complex) do
      { user: complex_class.new(user) }
    end
    let(:simple) do
      { 'user' => user }
    end

    it 'converts the complex hash to a simple hash' do
      expect(described_class.avro_to_h(complex)).to match(simple)
    end

    it 'keeps already simple hashes untouched' do
      expect(described_class.avro_to_h(simple)).to be_eql(simple)
    end
  end
end
