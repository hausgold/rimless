# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomConsumer do
  let(:topic) { Rimless.topic(app: :your_app, name: :your_topic) }
  let(:instance) { karafka_consumer_for(topic) }
  let(:action) { instance.consume }
  let(:params) { kafka_message(topic: topic, **payload) }

  before { allow(instance).to receive(:params).and_return(params) }

  context 'with custom_event message' do
    let(:payload) do
      { event: 'custom_event', property1: 'test', property2: nil }
    end

    it 'returns the payload properties' do
      expect(action).to eql(['test', nil])
    end
  end
end
