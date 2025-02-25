# frozen_string_literal: true

require 'karafka/cli/base'

module Karafka
  class Cli
    # See: https://github.com/hausgold/rimless/issues/36
    #
    # Karafka 1.4 is not compatible with Thor 1.3. Unfortunately they did not
    # backported the fix on Karafka 2.0 back to 1.4, so we have to do it here
    # with a monkey-patch.
    class Base
      class << self
        alias original_bind_to bind_to

        # This method will bind a given Cli command into Karafka Cli.
        # This method is a wrapper to way Thor defines its commands.
        #
        # @param cli_class [Karafka::Cli] the class to bind to
        #
        # rubocop:disable Metrics/MethodLength -- because of the
        #   monkey-patching logic
        def bind_to(cli_class)
          @aliases ||= []
          @options ||= []

          # We're late to the party here, as the +karafka/cli/console+ and
          # +karafka/cli/server+ files were already required and therefore they
          # already wrote to the +@options+ array. So we will sanitize/split
          # the options here to allow correct usage of the original Karafka 1.4
          # +.bind_to+ method.
          @options.select! do |set|
            # We look for option sets without name (aliases),
            # a regular set looks like this: +[:daemon, {:default=>false, ..}]+
            next true unless set.first.is_a? Hash

            # An alias looks like this: +[{:aliases=>"s"}]+
            @aliases << set.first[:aliases].to_s

            # Strip this set from the options
            false
          end

          # Run the original Karafka 1.4 +.bind_to+ method
          original_bind_to(cli_class)

          # Configure the command aliases
          @aliases.each do |cmd_alias|
            cli_class.map cmd_alias => name.to_s
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
