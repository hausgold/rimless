# frozen_string_literal: true

# Just for testing purposes, we can ignore and swallow raised exceptions.
#
# @yield
def ignore_raise
  yield
rescue StandardError
  :raised
end
