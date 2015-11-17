module Rester
  class Client
    class Response
      def initialize(status, hash={})
        @_status = status
        @_data = hash || {}
        _deep_freeze
      end

      def successful?
        @_status && @_status.between?(200, 299)
      end

      def to_h
        @_data.dup
      end

      def ==(obj)
        @_data == obj
      end

      private

      def method_missing(meth, *args, &block)
        if @_data.respond_to?(meth)
          @_data.public_send(meth, *args, &block)
        else
          super
        end
      end

      def _deep_freeze(value=@_response)
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