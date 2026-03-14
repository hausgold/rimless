# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Configuration do
  let(:instance) { described_class.new }

  describe '#kafka_brokers' do
    let(:action) { instance.kafka_brokers }

    context 'with KAFKA_BROKERS environment variable' do
      before { ENV['KAFKA_BROKERS'] = env_var }

      after { ENV.delete('KAFKA_BROKERS') }

      context 'with old format' do
        let(:env_var) { 'kafka://host1:9092,kafka://host2:9092' }

        it 'returns the correct configuration' do
          expect(action).to eql('host1:9092,host2:9092')
        end
      end

      context 'with new format' do
        let(:env_var) { 'host1:9092,host2:9092' }

        it 'returns the correct configuration' do
          expect(action).to eql('host1:9092,host2:9092')
        end
      end
    end

    context 'with setter' do
      before { instance.kafka_brokers = input }

      context 'with String' do
        context 'with old format' do
          let(:input) { 'kafka://host1:9092,kafka://host2:9092' }

          it 'returns the correct configuration' do
            expect(action).to eql('host1:9092,host2:9092')
          end
        end

        context 'with new format' do
          let(:input) { 'host1:9092,host2:9092' }

          it 'returns the correct configuration' do
            expect(action).to eql('host1:9092,host2:9092')
          end
        end
      end

      context 'with Array of strings' do
        context 'with old format' do
          let(:input) { ['kafka://host1:9092', 'kafka://host2:9092'] }

          it 'returns the correct configuration' do
            expect(action).to eql('host1:9092,host2:9092')
          end
        end

        context 'with new format' do
          let(:input) { ['host1:9092', 'host2:9092'] }

          it 'returns the correct configuration' do
            expect(action).to eql('host1:9092,host2:9092')
          end
        end

        context 'with mixed formats' do
          let(:input) { ['host1:9092', 'kafka://host2:9092'] }

          it 'returns the correct configuration' do
            expect(action).to eql('host1:9092,host2:9092')
          end
        end
      end
    end
  end

  describe '#consumer_job_queue' do
    let(:action) { instance.consumer_job_queue }

    after { instance.consumer_job_class.queue_as(:default) }

    context 'with environment variable' do
      context 'with KAFKA_JOB_QUEUE' do
        before { ENV['KAFKA_JOB_QUEUE'] = 'test' }

        after { ENV.delete('KAFKA_JOB_QUEUE') }

        it 'returns the correct configuration' do
          expect(action).to be(:test)
        end
      end

      context 'with KAFKA_SIDEKIQ_JOB_QUEUE' do
        before { ENV['KAFKA_SIDEKIQ_JOB_QUEUE'] = 'test' }

        after { ENV.delete('KAFKA_SIDEKIQ_JOB_QUEUE') }

        it 'returns the correct configuration' do
          expect(action).to be(:test)
        end
      end

      context 'with both' do
        before do
          ENV['KAFKA_JOB_QUEUE'] = 'test'
          ENV['KAFKA_SIDEKIQ_JOB_QUEUE'] = 'other'
        end

        after do
          ENV.delete('KAFKA_JOB_QUEUE')
          ENV.delete('KAFKA_SIDEKIQ_JOB_QUEUE')
        end

        it 'returns the correct configuration' do
          expect(action).to be(:test)
        end
      end
    end

    context 'with String' do
      it 'returns a Symbol' do
        instance.consumer_job_queue = 'test'
        expect(action).to be(:test)
      end
    end

    describe 'queue configuration' do
      let(:action) { instance.consumer_job_queue = 'kafka-messages' }

      it 'reconfigures the job queue' do
        expect { action }.to \
          change(instance.consumer_job_class, :queue_name)
          .from('default').to('kafka-messages')
      end
    end
  end
end
