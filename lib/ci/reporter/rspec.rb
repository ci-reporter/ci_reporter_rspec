require 'ci/reporter/core'

module CI::Reporter
  require 'ci/reporter/rspec2/formatter'
  RSpecFormatter = CI::Reporter::RSpec2::Formatter
end
