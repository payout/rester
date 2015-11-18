module Rester
  class Client
    class Response
      def initialize(status, hash={})
        @_status = status
        @_data = hash.dup || {}
        Utils.deep_freeze(@_data)
        freeze
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

      def respond_to_missing?(meth, include_private=false)
        @_data.respond_to?(meth) || super
      end
    end # Response
  end # Client
end # Rester