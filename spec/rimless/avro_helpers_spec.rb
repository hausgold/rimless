# frozen_string_literal: true

RSpec.describe Rimless::AvroHelpers do
  let(:described_class) { Rimless }

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
