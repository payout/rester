module Rester
  module Middleware
    ##
    # Sets the correlation id for the current thread if one is passed in the
    # request header. Clean up the correlation id for this thread before
    # responding.
    class CorrelationId < Base
      def call(env)
        Rester.correlation_id = env['X-Rester-Correlation-ID']
        super.tap { |response|
          Rester.correlation_id = nil
        }
      end
    end # CorrelationId
  end # Middleware
end # Rester
