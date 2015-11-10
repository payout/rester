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
        code = _error_to_http_code(error)

        unless [401, 403, 404].include?(code)
          body_h = {
            message: error.message,
            error: _error_name(error)
          }

          if code == 500
            body_h[:backtrace] = error.backtrace
          end
        end

        body = body_h ? [JSON.dump(body_h)] : []
        Rack::Response.new(body, code, { "Content-Type" => "application/json"})
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

      def _error_name(exception)
        Utils.underscore(exception.class.name.split('::').last.sub('Error', ''))
      end
    end # ErrorHandling
  end # Middleware
end # Rester
