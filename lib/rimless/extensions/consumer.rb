# frozen_string_literal: true

module Rimless
  module Extensions
    # The top-level Apache Kafka message consumer integration.
    module Consumer
      extend ActiveSupport::Concern

      class_methods do
        # A simple shortcut to fetch the Karafka-wrapping consumer application.
        #
        # @return [Rimless::Consumer::App] the internal consumer
        #   application class
        def consumer
          @consumer ||= Rimless::Consumer::App.new
        end
      end
    end
  end
end
