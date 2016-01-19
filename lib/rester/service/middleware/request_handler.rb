module Rester
  module Service::Middleware
    ##
    # Create a Request object for this thread, store the correlation ID, and
    # perform the necessary logging. Cleanup the request once it's complete.
    class RequestHandler < Base
      def call(env)
        Rester.begin_request
        Rester.request = Rester::Service::Request.new(env)
        correlation_id = Rester.request.correlation_id
        Rester.correlation_id = correlation_id

        path = Rester.request.path_info
        verb = Rester.request.request_method
        consumer_name = Rester.request.consumer_name

        service.logger.info("Correlation-ID=#{correlation_id}: " \
          "#{consumer_name} -> [#{service.name}] - #{verb} #{path}")

        response_log = "Correlation-ID=#{correlation_id}: " \
          "#{consumer_name} <- [#{service.name}] - #{verb} #{path}"

        super.tap { |response|
          response[1]["X-Rester-Producer-Name"] = service.name
          service.logger.info("#{response_log} #{response[0]}")
        }
      rescue Exception => e
        service.logger.error("#{response_log} #{e.inspect}")
        raise
      ensure
        Rester.end_request
      end
    end # RequestHandler
  end # Service::Middleware
end # Rester