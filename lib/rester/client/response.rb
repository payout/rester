module Rester
  class Client
    class Response < Hash
      def initialize(status, hash={})
        @_status = status
        merge!(hash)
        _deep_freeze
      end

      def successful?
        @_status && @_status.between?(200, 299)
      end

      private

      def _deep_freeze(value=self)
        value.freeze

        case value
        when Hash
          value.values.each { |v| _deep_freeze(v) }
        when Array
          value.each { |v| _deep_freeze(v) }
        end
      end
    end # Response
  end # Client
end # Rester