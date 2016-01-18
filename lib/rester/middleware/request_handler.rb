module Rester
  module Middleware
    ##
    # Sets the correlation id for the current thread if one is passed in the
    # request header. Clean up the correlation id for this thread before
    # responding.
    class RequestHandler < Base
      def call(env)
        Rester.request_info = Rester::Service::Request.new(env)

        path = env['PATH_INFO']
        verb = env['REQUEST_METHOD']
        consumer_name = Rester.request_info.consumer_name
        correlation_id = Rester.request_info.correlation_id
        service.logger.info("Correlation-ID=#{correlation_id}: " \
          "#{consumer_name} -> [#{service.name}] - #{verb} #{path}")

        response = super
      # rescue Exception => e
      #   puts "EXCEPTION #{e.inspect}"
      #   service.logger.info("Correlation-ID=#{correlation_id}: " \
      #     "#{consumer_name} <- [#{service.name}] - #{verb} " \
      #     "#{path} #{e.inspect}")
      #   raise
      ensure
        if response
          response[1]["HTTP_X_RESTER_PRODUCER_NAME"] = service.name
          service.logger.info("Correlation-ID=#{correlation_id}: " \
            "#{consumer_name} <- [#{service.name}] - #{verb} " \
            "#{path} #{response[1]}")
        end

        Rester.request_info = nil
      end
    end # RequestHandler
  end # Middleware
end # Rester