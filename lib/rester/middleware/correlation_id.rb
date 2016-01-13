module Rester
  module Middleware
    ##
    # Sets the correlation id for the current thread if one is passed in the
    # request header
    class CorrelationId < Base
      def call(env)
        Rester.correlation_id = env['X-Rester-Correlation-ID']
        super.tap { Rester.correlation_id = nil }
      end
    end # CorrelationId
  end # Middleware
end # Rester
