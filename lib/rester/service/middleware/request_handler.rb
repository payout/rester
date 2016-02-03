module Rester
  module Service::Middleware
    ##
    # Create a Request object for this thread, store the correlation ID, and
    # perform the necessary logging. Cleanup the request once it's complete.
    class RequestHandler < Base
      def call(env)
        Rester.wrap_request do
          Rester.request = request = Rester::Service::Request.new(env)
          Rester.correlation_id = request.correlation_id
          Rester.request_info[:producer_name] = service.name
          Rester.request_info[:consumer_name] = request.consumer_name
          Rester.request_info[:path] = request.path_info
          Rester.request_info[:verb] = request.request_method

          service.logger.info('request received')

          start_time = Time.now.to_f
          super.tap { |response|
            elapsed_ms = (Time.now.to_f - start_time) * 1000
            response[1]["X-Rester-Producer-Name"] = service.name
            service.logger.info("responding with #{response[0]} after %0.3fms" %
              elapsed_ms)
          }
        end
      end
    end # RequestHandler
  end # Service::Middleware
end # Rester
