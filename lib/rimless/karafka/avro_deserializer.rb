# frozen_string_literal: true

module Rimless
  module Karafka
    # A custom Apache Avro compatible message deserializer.
    class AvroDeserializer
      # Deserialize an Apache Avro encoded Apache Kafka message.
      #
      # @param params [Karafka::Params::Params] the Karafka message parameters
      # @return [Hash{Symbol => Mixed}] the deserialized Apache Avro message
      def call(params)
        # When the Kafka message does not have a payload, we won't fail.
        # This is for Kafka users which use log compaction with a nil payload.
        return if params.raw_payload.nil?

        # We use sparsed hashes inside of Apache Avro messages for schema-less
        # blobs of data, such as loosely structured metadata blobs.  Thats a
        # somewhat bad idea on strictly typed and defined messages, but their
        # occurence should be rare.
        Rimless
          .decode(params.raw_payload)
          .yield_self { |data| Sparsify(data, sparse_array: true) }
          .yield_self { |data| data.transform_keys { |key| key.delete('\\') } }
          .yield_self { |data| Unsparsify(data, sparse_array: true) }
          .deep_symbolize_keys
      end
    end
  end
end
