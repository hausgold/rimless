# frozen_string_literal: true

# Return a datum which is compatible to the test schema.
#
# @param deep [Hash{Symbol => String}] a different deep hash to embed
# @return [Hash{String => Mixed}] the datum
def avro_data(deep = nil)
  deep ||= { test: 'true', fancy: 'data' }
  Rimless.avro_sanitize(name: 'test',
                        include: {
                          id: 'uuid-v4'
                        },
                        deep: deep)
end
