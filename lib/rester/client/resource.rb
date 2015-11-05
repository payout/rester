module Rester
  class Client
    class Resource
      attr_reader :client
      attr_reader :path

      def initialize(client, path='')
        @client = client
        @path = path
      end

      def get(params={})
        _request(:get, '', params)
      end

      def update(params={})
        _request(:put, '', params)
      end

      def delete(params={})
        _request(:delete, '', params)
      end

      private

      def method_missing(meth, *args, &block)
        meth = meth.to_s
        arg = args.first

        case arg
        when Hash, NilClass
          _handle_search_or_create(meth, arg || {})
        when String, Symbol
          Resource.new(client, _path(meth, arg))
        else
          raise ArgumentError, "invalid argument type #{arg.inspect}"
        end
      end

      def _request(verb, path, params={})
        client.request(verb, _path(path), params)
      end

      def _path(*args)
        Utils.join_paths(path, *args)
      end

      def _handle_search_or_create(name, params)
        verb, name = Utils.extract_method_verb(name)
        _request(verb, name, params)
      end
    end # Resource
  end # Client
end # Rester
