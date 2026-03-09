# frozen_string_literal: true

module Rimless
  module Consumer
    # A custom Apache Avro compatible message deserializer.
    class AvroDeserializer
      # Deserialize an Apache Avro encoded Apache Kafka message.
      #
      # @param message [Karafka::Messages::Message] the Karafka message to
      #   deserialize
      # @return [Hash{Symbol => Mixed}, nil] the deserialized Apache Avro
      #   message, or +nil+ when we received a tombstone message
      def call(message)
        # When the Kafka message does not have a payload, we won't fail.
        # This is for Kafka users which use log compaction with a nil payload.
        return if message.raw_payload.nil?

        # TODO: Implement timestamp decoding?

        # We use sparsed hashes inside of Apache Avro messages for schema-less
        # blobs of data, such as loosely structured metadata blobs.  That's a
        # somewhat bad idea on strictly typed and defined messages, but their
        # occurrence should be rare.
        Rimless
          .decode(message.raw_payload)
          .then { |data| Sparsify(data, sparse_array: true) }
          .then { |data| data.transform_keys { |key| key.delete('\\') } }
          .then { |data| Unsparsify(data, sparse_array: true) }
          .deep_symbolize_keys
      end
    end
  end
end
