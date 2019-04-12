# frozen_string_literal: true

# Set the gem configuration according to the test suite.
def reset_test_configuration!
  Rimless.reset_configuration!
  Rimless.configure do |conf|
    conf.app_name = 'test-app'
    conf.env = 'test'
    conf.client_id = 'test-app'
    conf.logger = Logger.new(IO::NULL)
    conf.avro_schema_path = fixtures_path.join('files', 'avro_schemas')
    conf.compiled_avro_schema_path = tmp_path.join('compiled_avro_schemas')
  end
end
