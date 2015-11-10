module Rester
  class Client
    class Response < Hash
      def initialize(status, hash={})
        @_status = status
        merge!(hash)
      end

      def successful?
        @_status && @_status.between?(200, 299)
      end
    end # Response
  end # Client
end # Rester