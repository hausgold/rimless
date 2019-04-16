# frozen_string_literal: true

RSpec.describe Rimless::Dependencies do
  let(:described_class) { Rimless }

  describe '.configure_dependencies' do
    after { described_class.configure_dependencies }

    it 'calls configure_waterdrop' do
      expect(described_class).to receive(:configure_waterdrop).once
    end

    it 'calls configure_avro_turf' do
      expect(described_class).to receive(:configure_avro_turf).once
    end
  end

  describe '.configure_waterdrop' do
    after { described_class.configure_waterdrop }

    it 'calls the WaterDrop setup method' do
      expect(WaterDrop).to receive(:setup).once
    end

    it 'sets the configured logger' do
      expect(Rimless).to receive(:logger).once.and_call_original
    end

    it 'sets the client id' do
      expect(Rimless.configuration).to \
        receive(:client_id).at_least(:once).and_call_original
    end

    it 'sets the kafka brokers' do
      expect(Rimless.configuration).to \
        receive(:kafka_brokers).at_least(:once).and_call_original
    end
  end

  describe '.configure_avro_turf' do
    after { described_class.configure_avro_turf }

    it 'sets the configured logger' do
      expect(Rimless).to receive(:logger).once.and_call_original
    end

    it 'sets the schema registry url' do
      expect(Rimless.configuration).to \
        receive(:schema_registry_url).once.and_call_original
    end

    # rubocop:disable RSpec/AnyInstance because it cannot be substituted
    it 'recompiles the Apache Avro schema templates' do
      expect_any_instance_of(Rimless::AvroUtils).to \
        receive(:recompile_schemas).once
    end
    # rubocop:enable RSpec/AnyInstance

    it 'sets the global Apache Avro handle' do
      Rimless.avro = nil
      expect { described_class.configure_avro_turf }.to \
        change(Rimless, :avro).from(nil).to(AvroTurf::Messaging)
    end

    it 'sets the correct schema path' do
      expect(AvroTurf::Messaging).to receive(:new)
        .with(a_hash_including(
                schemas_path: tmp_path.join('compiled_avro_schemas')
              ))
    end

    it 'sets the correct namespace' do
      expect(AvroTurf::Messaging).to receive(:new)
        .with(a_hash_including(
                namespace: 'test.test_app'
              ))
    end
  end
end
