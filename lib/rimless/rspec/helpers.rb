# frozen_string_literal: true

module Rimless
  # Some general RSpec testing stuff.
  module RSpec
    # A collection of Rimless/RSpec helpers.
    module Helpers
      # A simple helper to parse a blob of Apache Avro data.
      #
      # @param data [String] the Apache Avro blob
      # @return [Hash{String => Mixed}] the parsed payload
      def avro_parse(data)
        Rimless.avro.decode(data)
      end
    end
  end
end
