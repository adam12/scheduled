# frozen-string-literal: true

module Scheduled
  module Instrumenters
    ##
    # An Instrumentor that performs work without measurement
    class Noop
      def self.instrument(name, payload = {})
        yield payload if block_given?
      end
    end
  end
end
