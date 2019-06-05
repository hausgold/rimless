# frozen_string_literal: true

# Return a datum which is compatible to the test schema.
#
# @param deep [Hash{Symbol => String}] a different deep hash to embed
# @return [Hash{Symbol => Mixed}] the datum
def avro_data_symbol_keys(deep = nil)
  deep ||= { test: 'true', fancy: 'data' }
  { name: 'test', include: { id: 'uuid-v4' }, deep: deep }
end

# Return a datum which is compatible to the test schema.
#
# @param deep [Hash{Symbol => String}] a different deep hash to embed
# @return [Hash{String => Mixed}] the datum
def avro_data(deep = nil)
  Rimless.avro_sanitize(avro_data_symbol_keys(deep))
end
