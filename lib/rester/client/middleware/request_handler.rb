module Rester
  module Client::Middleware
    class RequestHandler
      def call(env)
        Rester.begin_request
        super
      ensure
        Rester.end_request
      end
    end # RequestHandlers
  end # Client::Middleware
end # Rester
