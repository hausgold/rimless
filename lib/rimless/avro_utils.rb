# frozen_string_literal: true

module Rimless
  # Due to dynamic contrains on the Apache Avro schemas we need to compile our
  # schema templates to actual ready-to-consume schemas. The namespace part of
  # the schemas and cross-references to other schemas must be rendered
  # according to the dynamic namespace prefix which reflects the application
  # environment.  Unfortunately we need to mess around with actual files to
  # support the Avro and AvroTurf gems.
  class AvroUtils
    attr_reader :namespace, :env

    # Create a new instance of the +AvroUtil+ class.
    #
    # @return [AvroUtil] the new instance
    def initialize
      @namespace = ENV.fetch('KAFKA_SCHEMA_SUBJECT_PREFIX',
                             Rimless.topic_prefix).tr('-', '_').gsub(/\.$/, '')
      @env = @namespace.split('.').first
    end

    # Clean and recompile all templated Avro schema files to their respective
    # output path.
    def recompile_schemas
      clear
      Dir[base_path.join('**', '*.erb')].each { |src| render_file(src) }
    end

    # Render (compile) a single Avro schema template. The given source file
    # path will serve to calculate the destination path. So even deep path'ed
    # templates will keep their hierarchy.
    #
    # @param src [String] the Avro schema template file path
    def render_file(src)
      # Convert the template path to the destination path
      dest = schema_path(src)
      # Create the deep path when not yet existing
      FileUtils.mkdir_p(File.dirname(dest))
      # Write the rendered file contents to the destination
      File.write(dest, ERB.new(File.read(src)).result(binding))
      # Check the written file for correct JSON
      validate_file(dest)
    end

    # Check the given file for valid JSON.
    #
    # @param dest [Pathname, File, IO] the file to check
    # @raise [JSON::ParserError] when invalid
    #
    # rubocop:disable Security/JSONLoad because we wrote the file contents
    def validate_file(dest)
      JSON.load(dest)
    rescue JSON::ParserError => err
      path = File.expand_path(dest.is_a?(File) ? dest.path : dest.to_s)
      prefix = "Invalid JSON detected: #{path}"
      Rimless.logger.fatal("#{prefix}\n#{err.message}")
      err.message.prepend("#{prefix} - ")
      raise err
    end
    # rubocop:enable Security/JSONLoad

    # Clear previous compiled Avro schema files to provide a clean rebuild.
    def clear
      # In a test environment, especially with parallel test execution the
      # recompiling of Avro schemas is error prone due to the deletion of the
      # configuration (output) directory. This leads to random failures due to
      # file read calls to temporary not existing files. So we just keep the
      # files and just overwrite them in place while testing.
      FileUtils.rm_rf(output_path) unless Rimless.env.test?
      FileUtils.mkdir_p(output_path)
    end

    # Return the compiled Avro schema file path for the given Avro schema
    # template.
    #
    # @param src [String] the Avro schema template file path
    # @return [Pathname] the resulting schema file path
    def schema_path(src)
      # No trailing dot on the prefix namespace directory
      prefix = env.remove(/\.$/)
      # Calculate the destination path based on the source file
      Pathname.new(src.gsub(/^#{base_path}/, output_path.join(prefix).to_s)
                      .gsub(/\.erb$/, ''))
    end

    # Return the base path of the Avro schemas on our project.
    #
    # @return [Pathname] the Avro schemas base path
    def base_path
      Rimless.configuration.avro_schema_path
    end

    # Return the path to the compiled Avro schemas. This path must be consumed
    # by the +AvroTurf::Messaging+ constructor.
    #
    # @return [Pathname] the compiled Avro schemas path
    def output_path
      Rimless.configuration.compiled_avro_schema_path
    end
  end
end
