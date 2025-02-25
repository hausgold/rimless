# frozen_string_literal: true

namespace :rimless do
  require 'fileutils'

  # Install a template file to the project.
  #
  # @param src [String] the template source file name
  # @param dest [Array<String>] the relative destination parts
  def install_template(src, *dest)
    src = File.join(__dir__, 'templates', src)
    dest = File.join(Dir.pwd, *dest, File.basename(src))

    return puts "#    [Skip] #{dest}" if File.exist? dest

    puts "# [Install] #{dest}"
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.copy(src, dest)
  end

  # rubocop:disable Rails/RakeEnvironment -- because this is just an helper
  #   command, no need for an application bootstrap
  desc 'Install the Rimless consumer components'
  task :install do
    install_template('karafka.rb')
    install_template('application_consumer.rb', 'app', 'consumers')
    install_template('custom_consumer.rb', 'app', 'consumers')
    install_template('custom_consumer_spec.rb', 'spec', 'consumers')

    puts <<~OUTPUT
      #
      # Installation done.
      #
      # You can now configure your routes at the +karafka.rb+ file at
      # your project root. And list all routes with +rake rimless:routes+.
    OUTPUT
  end
  # rubocop:enable Rails/RakeEnvironment
end
