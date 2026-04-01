# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Consumer::Job do
  let(:job) { described_class.new }

  describe '#perform' do
    let(:action) { job.perform(payload:, consumer:, metadata:) }
    let(:payload) { { event: 'test', test: true } }
    let(:consumer) { 'Rimless::Consumer::Base' }
    let(:metadata) { { key: 'test-key' } }
    let(:consumer_instance) { consumer.constantize.new }

    before do
      allow(consumer.constantize).to \
        receive(:build_for_job).and_return(consumer_instance)
      allow(consumer_instance).to receive(:messages).and_return([])
    end

    it 'instantiates the given consumer' do
      expect(consumer.constantize).to \
        receive(:build_for_job).once.and_return(consumer_instance)
      action
    end

    it 'calls the consume method on the consumer' do
      expect(consumer_instance).to receive(:consume).once
      action
    end
  end
end
