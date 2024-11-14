# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer do
  let(:described_class) { Rimless }

  describe '.consumer' do
    it 'returns the Rimless::ConsumerApp class' do
      expect(described_class.consumer).to be(Rimless::ConsumerApp)
    end

    it 'initializes the consumer application' do
      expect(Rimless::ConsumerApp).to receive(:initialize!).once
      described_class.consumer
    end
  end

  describe Rimless::ConsumerApp do
    # rubocop:disable RSpec/DescribedClass because of the class-nesting
    let(:described_class) { Rimless::ConsumerApp }
    # rubocop:enable RSpec/DescribedClass

    describe '.configure' do
      let(:action) do
        described_class.configure do |config|
          config.kafka.start_from_beginning = false
        end
      end

      it 'allows to configure ruby-kafka settings' do
        expect { action }.to \
          change(described_class.config.kafka, :start_from_beginning)
          .from(true).to(false)
      end
    end

    describe '.topics' do
      let(:topics) { Rimless.consumer.consumer_groups.first.topics }

      before { described_class.consumer_groups.clear }

      context 'with topics, without block' do
        before do
          described_class.topics(topic1: Rimless::BaseConsumer,
                                 topic2: Rimless::BaseConsumer)
        end

        it 'configures a single consumer group' do
          expect(Rimless.consumer.consumer_groups.count).to be(1)
        end

        it 'configures the correct consumer group name' do
          expect(Rimless.consumer.consumer_groups.first.name).to \
            eql('test-app')
        end

        it 'configures two topics' do
          expect(topics.count).to be(2)
        end

        it 'configures the first topic name correctly' do
          expect(topics.first.name).to eql('test.test-app.topic1')
        end

        it 'configures the first topic consumer correctly' do
          expect(topics.first.consumer).to be(Rimless::BaseConsumer)
        end

        it 'configures the first topic worker correctly' do
          expect(topics.first.worker).to be(Rimless::ConsumerJob)
        end

        it 'configures the first topic interchanger correctly' do
          expect(topics.first.interchanger).to \
            be_a(Rimless::Karafka::Base64Interchanger)
        end

        it 'configures the second topic name correctly' do
          expect(topics.last.name).to eql('test.test-app.topic2')
        end

        it 'configures the second topic consumer correctly' do
          expect(topics.last.consumer).to be(Rimless::BaseConsumer)
        end

        it 'configures the second topic worker correctly' do
          expect(topics.last.worker).to be(Rimless::ConsumerJob)
        end

        it 'configures the second topic interchanger correctly' do
          expect(topics.last.interchanger).to \
            be_a(Rimless::Karafka::Base64Interchanger)
        end
      end

      context 'without topics, but a block' do
        before do
          described_class.topics do
            topic('my.custom.topic') do
              consumer Rimless::BaseConsumer
            end
          end
        end

        it 'configures the topic name correctly' do
          expect(topics.last.name).to eql('my.custom.topic')
        end

        it 'configures the topic consumer correctly' do
          expect(topics.last.consumer).to be(Rimless::BaseConsumer)
        end
      end
    end

    describe '.topic_names' do
      let(:action) { described_class.topic_names(parts) }

      context 'with a string' do
        let(:parts) { 'admins' }

        it 'returns an array with correct elements' do
          expect(action).to eql(%w[test.test-app.admins])
        end
      end

      context 'with a symbol' do
        let(:parts) { :admins }

        it 'returns an array with correct elements' do
          expect(action).to eql(%w[test.test-app.admins])
        end
      end

      context 'with a hash, with single name' do
        let(:parts) { { app: :test_api, name: :admins } }

        it 'returns an array with correct elements' do
          expect(action).to eql(%w[test.test-api.admins])
        end
      end

      context 'with a hash, with multiple names' do
        let(:parts) { { app: :test_api, names: %i[customers admins] } }

        it 'returns an array with correct elements' do
          expect(action).to \
            eql(%w[test.test-api.customers test.test-api.admins])
        end
      end
    end
  end
end
