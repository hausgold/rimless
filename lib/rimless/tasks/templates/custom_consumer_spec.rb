# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomConsumer do
  let(:topic) { Rimless.topic(app: :your_app, name: :your_topic) }
  let(:instance) { kafka_consumer_for(topic) }
  let(:action) { instance.consume }
  let(:message) { kafka_message(topic: topic, **payload) }

  before { allow(instance).to receive(:messages).and_return([message]) }

  context 'with custom_event message' do
    let(:payload) do
      { event: 'custom_event', property1: 'test', property2: nil }
    end

    it 'returns the payload properties' do
      expect(Rails.logger).to receive(:debug).with(['test', nil]).once
      action
    end
  end
end
