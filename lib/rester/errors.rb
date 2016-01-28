module Rester
  module Errors
    class << self
      ##
      # Throws an error instead of raising it, which is more performant. Must
      # be caught by an appropriate error handling wrapper.
      def throw_error!(error, message = nil)
        error = error.new(message) if error.is_a?(Class)
        throw :error, error
      end
    end # Class Methods

    class Error < StandardError; end
    class MethodError < Error; end
    class MethodDefinitionError < MethodError; end

    ################
    # Adapter Errors
    class AdapterError < Error; end
    class TimeoutError < AdapterError; end

    ###############
    # Client Errors
    class ClientError < Error; end
    class CircuitOpenError < ClientError; end
    class ConnectionError < ClientError; end

    #############
    # Stub Errors
    class StubError < Error; end

    #############
    # RSpec Errors
    class RSpecError < Error; end
    class TestError < RSpecError; end

    #############
    # Http Errors
    class HttpError < Error; end

    ##
    # 400 Errors
    class RequestError < HttpError
      attr_reader :error

      def initialize(error, message = nil)
        @error = error
        super(message)
      end
    end

    class ValidationError < RequestError
      def initialize(message = nil)
        super('validation', message)
      end
    end

    ##
    # 401 Error
    class AuthenticationError < HttpError; end

    ##
    # 403 Error
    class ForbiddenError < HttpError; end

    ##
    # 404 Not Found
    class NotFoundError < HttpError; end

    ##
    # 500 ServerError
    class ServerError < HttpError; end
  end # Errors
end # Rester
