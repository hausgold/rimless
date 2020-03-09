# frozen_string_literal: true

module Rimless
  module Karafka
    # A custom Apache Avro compatible message deserializer.
    class AvroDeserializer
      # Deserialize an Apache Avro encoded Apache Kafka message.
      #
      # @param message [String] the binary blob to deserialize
      # @return [Hash{Symbol => Mixed}] the deserialized Apache Avro message
      def call(message)
        # We use sparsed hashes inside of Apache Avro messages for schema-less
        # blobs of data, such as loosely structured metadata blobs.  Thats a
        # somewhat bad idea on strictly typed and defined messages, but their
        # occurence should be rare.
        Rimless
          .decode(message.payload)
          .yield_self { |data| Sparsify(data, sparse_array: true) }
          .yield_self { |data| data.transform_keys { |key| key.delete('\\') } }
          .yield_self { |data| Unsparsify(data, sparse_array: true) }
          .deep_symbolize_keys
      end
    end
  end
end
