module Rester
  module Errors
    class << self
      ##
      # Throws an error instead of raising it, which is more performant. Must
      # be caught by an appropriate error handling wrapper.
      def throw_error!(klass, message=nil)
        error = message ? klass.new(message) : klass.new
        throw :error, error
      end
    end # Class Methods

    class Error < StandardError; end

    ##
    # Packet errors
    class PacketError < Error; end
    class InvalidEncodingError < PacketError; end

    #############
    # Http Errors
    class HttpError < Error; end

    ##
    # Request Errors

    # 400 Error
    class RequestError < HttpError; end

    # 401 Error
    class AuthenticationError < RequestError; end

    # 403 Error
    class ForbiddenError < RequestError; end

    # 404 Not Found
    class NotFoundError < RequestError; end
    class InvalidMethodError < NotFoundError; end

    # 500 ServerError
    class ServerError < RequestError; end

    ##
    # Server Errors

    # General Errors
    class InvalidValueError < Error; end

    # Rester Errors
    class ServiceNotDefinedError < Error; end
  end # Errors
end # Rester
