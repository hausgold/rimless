# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::AvroUtils do
  let(:instance) { described_class.new }
  let(:src) do
    instance.base_path.join('test_app', 'test.avsc.erb').to_s
  end
  let(:dest) do
    instance.output_path.join('test', 'test_app', 'test.avsc').to_s
  end

  # rubocop:disable RSpec/BeforeAfterAll because we want to re-regenarate
  #   the Avro schemas for the rest of the test suite
  after(:all) { described_class.new.recompile_schemas }
  # rubocop:enable RSpec/BeforeAfterAll

  describe '#initialize' do
    context 'with prefix from environment variable' do
      before { ENV['KAFKA_SCHEMA_SUBJECT_PREFIX'] = 'abc.app.' }

      after { ENV.delete('KAFKA_SCHEMA_SUBJECT_PREFIX') }

      it 'sets the namespace prefix correctly' do
        expect(described_class.new.env).to eql('abc')
      end

      it 'sets the namespace correctly' do
        expect(described_class.new.namespace).to eql('abc.app')
      end
    end

    context 'with fallback prefix' do
      it 'sets the namespace prefix correctly' do
        expect(described_class.new.env).to eql('test')
      end

      it 'sets the namespace correctly' do
        expect(described_class.new.namespace).to eql('test.test_app')
      end
    end
  end

  describe '#base_path' do
    it 'returns a Pathname instance' do
      expect(instance.base_path).to be_a(Pathname)
    end

    it 'sets the correct base path' do
      expect(instance.base_path.to_s).to end_with('/files/avro_schemas')
    end
  end

  describe '#output_path' do
    it 'returns a Pathname instance' do
      expect(instance.output_path).to be_a(Pathname)
    end

    it 'sets the correct base path' do
      expect(instance.output_path.to_s).to \
        end_with('/tmp/compiled_avro_schemas')
    end
  end

  describe '#schema_path' do
    it 'returns the correct path' do
      expect(instance.schema_path(src).to_s).to eql(dest)
    end
  end

  describe '#clear' do
    let(:file) { instance.output_path.join('test', 'test.file') }

    before do
      Rimless.configuration.env = 'development'
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, 'test')
    end

    it 'clears compiled schemas' do
      expect { instance.clear }.to \
        change { File.exist? file }.from(true).to(false)
    end

    it 'recreates the output path' do
      expect { instance.clear }.not_to \
        change { File.exist? instance.output_path }.from(true)
    end
  end

  describe '#recompile_schemas' do
    it 'clears previous compiled files' do
      expect(instance).to receive(:clear).once
      instance.recompile_schemas
    end

    it 'calls the #render_file method for all templates' do
      expect(instance).to receive(:render_file).at_least(:twice)
      instance.recompile_schemas
    end
  end

  describe '#render_file' do
    let(:dest) do
      instance.output_path.join('development', 'test_app', 'test.avsc').to_s
    end

    before do
      Rimless.configuration.env = 'development'
      instance.clear
    end

    it 'creates the desired output file' do
      expect { instance.render_file(src) }.to \
        change { File.exist? dest }.from(false).to(true)
    end

    it 'replaces the ERB variables' do
      instance.render_file(src)
      expect(YAML.load_file(dest)).to \
        include('namespace' => 'development.test_app')
    end

    it 'checks for correct JSON' do
      expect(instance).to \
        receive(:validate_file).with(Pathname.new(dest)).once
      instance.render_file(src)
    end
  end

  describe '#validate_file' do
    let(:valid) { file_fixture('valid.json') }
    let(:invalid) { file_fixture('invalid.json') }

    it 'does not raise on valid JSON files' do
      expect { instance.validate_file(valid) }.not_to raise_error
    end

    it 'raises on invalid JSON files' do
      expect { instance.validate_file(invalid) }.to \
        raise_error(JSON::ParserError)
    end

    it 'logs the broken file and error' do
      expect(Rimless.logger).to receive(:fatal)
        .with(%r{files/invalid\.json.*unexpected token at}m).once
      ignore_raise { instance.validate_file(invalid) }
    end
  end
end
