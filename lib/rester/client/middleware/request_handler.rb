module Rester
  module Client::Middleware
    class RequestHandler < Base
      def call(env)
        Rester.wrap_request do
          Rester.correlation_id = SecureRandom.uuid
          Rester.request_info[:consumer_name] = Rester.service_name
          super
        end
      end
    end # RequestHandlers
  end # Client::Middleware
end # Rester
