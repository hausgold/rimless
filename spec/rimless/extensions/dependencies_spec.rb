# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Extensions::Dependencies do
  let(:described_class) { Rimless }

  describe '.configure_dependencies' do
    after { described_class.configure_dependencies }

    it 'calls configure_avro' do
      expect(described_class).to receive(:configure_avro).once
    end

    it 'calls configure_producer' do
      expect(described_class).to receive(:configure_producer).once
    end
  end

  describe '.configure_avro' do
    after { described_class.configure_avro }

    it 'sets the configured logger' do
      expect(Rimless).to receive(:logger).once.and_call_original
    end

    it 'sets the schema registry url' do
      expect(Rimless.configuration).to \
        receive(:schema_registry_url).at_least(:once).and_call_original
    end

    # rubocop:disable RSpec/AnyInstance -- because it cannot be substituted
    it 'recompiles the Apache Avro schema templates' do
      expect_any_instance_of(Rimless::AvroUtils).to \
        receive(:recompile_schemas).once
    end
    # rubocop:enable RSpec/AnyInstance

    it 'sets the global AvroUtils handle' do
      Rimless.avro_utils = nil
      expect { described_class.configure_avro }.to \
        change(Rimless, :avro_utils).from(nil).to(Rimless::AvroUtils)
    end

    it 'sets the global Apache Avro handle' do
      Rimless.avro = nil
      expect { described_class.configure_avro }.to \
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

    context 'with user configuration block' do
      before do
        Rimless.configuration.avro_configure = proc do |config|
          config.merge(password: 'secret')
        end
        described_class.configure_avro
      end

      it 'calls the avro_configure configuration' do
        con = Rimless.avro.instance_variable_get(:@registry)
                     .instance_variable_get(:@upstream)
                     .instance_variable_get(:@connection)
        expect(con.data[:password]).to eql('secret')
      end
    end
  end

  describe '.configure_producer' do
    before do
      Rimless.configuration.client_id = 'rimless-test'
      Rimless.configuration.kafka_brokers = 'a:1,b:2'
      described_class.configure_producer
    end

    it 'creates a WaterDrop::Producer instance' do
      expect(WaterDrop::Producer).to receive(:new).once
      described_class.configure_producer
    end

    it 'saves the WaterDrop::Producer for shared usage' do
      expect(Rimless.producer).to be_a(WaterDrop::Producer)
    end

    it 'enables the message delivery' do
      expect(Rimless.producer.config.deliver).to be(true)
    end

    it 'sets the configured logger' do
      expect(Rimless.producer.config.logger).to be(Rimless.logger)
    end

    it 'sets the kafka client id' do
      expect(Rimless.producer.config.kafka).to \
        include('client.id': 'rimless-test')
    end

    it 'sets the kafka brokers' do
      expect(Rimless.producer.config.kafka).to \
        include('bootstrap.servers': 'a:1,b:2')
    end

    it 'sets the kafka message acknowledgments' do
      expect(Rimless.producer.config.kafka).to \
        include('request.required.acks': -1)
    end

    context 'with user configuration block' do
      before do
        Rimless.configuration.producer_configure = proc do |config|
          config.kafka[:'request.required.acks'] = 0
        end
        described_class.configure_producer
      end

      it 'calls the producer_configure configuration' do
        expect(Rimless.producer.config.kafka).to \
          include('request.required.acks': 0)
      end
    end
  end
end
