# frozen_string_literal: true

# Return the project root path.
#
# @return [Pathname] the project root path
def root_path
  Pathname.new(File.expand_path(File.join(__dir__, '..', '..')))
end

# Return the test suite temporary path.
#
# @return [Pathname] the test suite temporary path
def tmp_path
  root_path.join('tmp')
end

# Return the test suite fixtures path.
#
# @return [Pathname] the test suite fixtures path
def fixtures_path
  root_path.join('spec', 'fixtures')
end
