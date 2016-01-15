module Rester
  module Middleware
    ##
    class Identify < Base
      def call(env)
        consumer_name = env['HTTP_X_RESTER_CONSUMER_NAME'] || "Consumer"
        path = env['PATH_INFO']
        verb = env['REQUEST_METHOD']
        Rester.logger.info("Correlation-ID=#{Rester.correlation_id}: " \
          "#{consumer_name} -> [#{service.class.service_name}] - #{verb} " \
          "#{path}")

        super.tap { |response|
          Rester.logger.info("Correlation-ID=#{Rester.correlation_id}: " \
            "#{consumer_name} <- [#{service.class.service_name}] - #{verb} " \
            "#{path} #{response[0]}")
        }
      end
    end # Identify
  end # Middleware
end # Rester
