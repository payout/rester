module Rester
  module Client::Adapters
    class HttpAdapter < Adapter
      autoload(:Connection, 'rester/client/adapters/http_adapter/connection')

      attr_reader :connection

      def connect(*args)
        nil.tap { @connection = Connection.new(*args) }
      end

      def connected?
        !!connection
      end

      def get!(path, params={})
        _prepare_response(connection.get(path, headers: headers, query: params))
      end

      def post!(path, params={})
        _prepare_response(connection.post(path, headers: headers, data: params))
      end

      private

      def _prepare_response(response)
        [response.code.to_i, response.body]
      end
    end # HttpAdapter
  end # Client::Adapters
end # Rester
