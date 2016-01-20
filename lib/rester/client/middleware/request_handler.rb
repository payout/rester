module Rester
  module Client::Middleware
    class RequestHandler < Base
      def call(env)
        Rester.begin_request
        Rester.correlation_id = SecureRandom.uuid
        super
      ensure
        Rester.end_request
      end
    end # RequestHandlers
  end # Client::Middleware
end # Rester
