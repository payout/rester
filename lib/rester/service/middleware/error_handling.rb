require 'json'

module Rester
  module Service::Middleware
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

        service.logger.error(error.inspect)
        _error_to_response(error).finish
      end

      private

      def _error_to_response(error)
        code = _error_to_http_code(error)

        unless [401, 403, 404].include?(code)
          body_h = { error: _error_name(error) }

          if error.message && error.message != error.class.name
            body_h.merge!(message: error.message)
          end

          if code == 500
            body_h[:backtrace] = error.backtrace
          end
        end

        body = body_h ? [JSON.dump(body_h)] : []
        Rack::Response.new(body, code, { "Content-Type" => "application/json"})
      end

      def _error_to_http_code(error)
        case error
        when Errors::RequestError
          400
        when Errors::AuthenticationError
          401
        when Errors::ForbiddenError
          403
        when Errors::NotFoundError
          404
        when Errors::ServerError
          500
        else
          500
        end
      end

      ##
      # Takes an exception and returns an appropriate name to return to the
      # client.
      def _error_name(error)
        case error
        when Errors::RequestError
          error.error
        else
          Utils.underscore(error.class.name.split('::').last.sub('Error', ''))
        end
      end
    end # ErrorHandling
  end # Service::Middleware
end # Rester
