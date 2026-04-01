# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rimless::Extensions::Consumer do
  let(:described_class) { Rimless }

  describe '.consumer' do
    it 'returns a Rimless::Consumer::App instance' do
      expect(described_class.consumer).to be_a(Rimless::Consumer::App)
    end

    # rubocop:disable RSpec/IdenticalEqualityAssertion -- because we
    #   check for memoization here
    it 'memoizes the consumer application instance' do
      expect(described_class.consumer).to be(described_class.consumer)
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion
  end
end
