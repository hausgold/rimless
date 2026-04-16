# frozen_string_literal: true

module Rimless
  module Consumer
    # A custom Apache Avro compatible message deserializer.
    class AvroDeserializer
      # The ISO8601 date/time format
      ISO_TIME_FORMAT = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?/m

      # The ISO8601 date format
      ISO_DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\Z/m

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
          .then do |obj|
            # When the configuration says we should not parse datetimes,
            # we skip further processing
            next obj \
              unless Rimless.configuration.avro_deserializer_parse_datetimes

            # Otherwise we parse them
            parse_timestamps!(obj)
          end
      end

      # Search recursively through the given object for ISO date/time string
      # values and replace them with their parsed date representation. This
      # works on hashes, arrays, and combinations of this.
      #
      # @param value [Mixed] the input to process
      # @return [Mixed] the processed input
      def parse_timestamps!(obj)
        case obj
        when Hash
          obj.each { |key, val| obj[key] = parse_timestamps!(val) }
        when Array
          obj.each_with_index { |cur, idx| obj[idx] = parse_timestamps!(cur) }
        when ISO_TIME_FORMAT
          Time.zone.parse(obj)
        when ISO_DATE_FORMAT
          Date.parse(obj)
        else
          obj
        end
      end
    end
  end
end
