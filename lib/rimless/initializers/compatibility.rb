# frozen_string_literal: true

# Check the actual (currently loaded) gem version against the expected
# (given) version. It returns +true+ when the expected version matches the
# actual one. The version check is patch-level independent.
#
# @param expected [String] the expected gem version (eg. +'~> 5.1'+)
# @return [Boolean] whenever the version is loaded or not
def rimless_gem_version?(gem_name, expected)
  actual = Gem.loaded_specs[gem_name].version
  Gem::Dependency.new('', expected.to_s).match?('', actual)
end

# Load some polyfills for ActiveSupport lower than 6.0
require 'rimless/compatibility/karafka_1_4' \
  if rimless_gem_version?('karafka', '~> 1.4') \
     && rimless_gem_version?('thor', '>= 1.3')
