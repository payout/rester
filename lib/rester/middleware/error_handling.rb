require 'json'

module Rester
  module Middleware
    ##
    # Provides error handling for Rester. Should be mounted above all other
    # Rester middleware.
    class ErrorHandling < Base
      def call(env)
        error = catch(:error) {
          begin
            return super
          rescue Exception => error
            throw :error, error
          end
        }

        _error_to_response(error).finish
      end

      private

      def _error_to_response(error)
        Rack::Response.new(
          [JSON.dump(message: error.message, backtrace: error.backtrace)],
          _error_to_http_code(error),
          { "Content-Type" => "application/json"}
        )
      end

      def _error_to_http_code(error)
        case error
        when Errors::NotFoundError
          404
        when Errors::ForbiddenError
          403
        when Errors::AuthenticationError
          401
        when Errors::RequestError
          400
        when Errors::ServerError
          500
        else
          500
        end
      end
    end # ErrorHandling
  end # Middleware
end # Rester
