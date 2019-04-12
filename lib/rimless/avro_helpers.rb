# frozen_string_literal: true

module Rimless
  # The top-level Apache Avro helpers.
  module AvroHelpers
    extend ActiveSupport::Concern

    class_methods do
      # A top-level avro instance
      mattr_accessor :avro

      # The Apache Avro Ruby gem requires simple typed hashes for encoding.
      # This forces us to convert eg. Grape entity representations into simple
      # string-keyed hashes. Use this method to prepare a hash for the Apache
      # Avro serialization.
      #
      # Note about the implementation: JSON serialization and parsing is the
      # simplest and fastest way to accomplish this.
      #
      # @param hash [Hash{Mixed => Mixed}] the hash to sanitize
      # @return [Hash{String => Mixed}] the simple typed input hash
      def avro_to_h(hash)
        JSON.parse(hash.to_json)
      end
      alias_method :avro_sanitize, :avro_to_h

      # Convert the given deep hash into a sparsed flat hash while transforming
      # all values to strings. This allows to convert a schema-less hash to a
      # Apache Avro compatible map.
      #
      # @see http://avro.apache.org/docs/current/spec.html#Maps
      # @example Convert schema-less hash
      #   avro_schemaless_map(a: { b: { c: true } })
      #   # => { "a.b.c" => "true" }
      #
      # @param hash [Hash{Mixed => Mixed}] the deep hash
      # @return [Hash{String => String}] the flatted and sparsed hash
      def avro_schemaless_h(hash)
        Sparsify(hash, sparse_array: true)
          .transform_values(&:to_s)
          .transform_keys { |key| key.delete('\\') }
      end
      alias_method :avro_schemaless_map, :avro_schemaless_h
    end
  end
end
