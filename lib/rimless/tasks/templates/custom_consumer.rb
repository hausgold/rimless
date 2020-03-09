# frozen_string_literal: true

# A dedicated consumer to handle event-messages from your producing application.
# Just write a method with the name of an event and it is called directly with
# all the event data as parameters.
class CustomConsumer < ApplicationConsumer
  # Handle +custom_event+ event messages.
  def custom_event(property1:, property2: nil)
    # Do whatever you need to do
    [property1, property2]
  end
end
