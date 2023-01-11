# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::BaseConsumer do
  let(:group) { Karafka::Routing::ConsumerGroup.new('test') }
  let(:topic) { Karafka::Routing::Topic.new('test', group) }
  let(:instance) do
    Class.new(Rimless::BaseConsumer) do
      def foo(bar:)
        bar
      end
    end.new(topic)
  end
  let(:params) do
    kafka_message(topic: 'test', event: 'foo', bar: 'foo', foo: 'bar')
  end

  before { allow(instance).to receive(:params).and_return(params) }

  describe '#consume' do
    it 'calls the correct method by event name' do
      expect(instance).to receive(:foo).with(bar: 'foo', foo: 'bar')
      instance.consume
    end
  end

  describe '#arguments' do
    it 'returns the correct arguments' do
      expect(instance.arguments).to be_eql(bar: 'foo', foo: 'bar')
    end
  end

  describe '#event' do
    it 'returns the correct event name' do
      expect(instance.event).to be_eql(:foo)
    end
  end
end
