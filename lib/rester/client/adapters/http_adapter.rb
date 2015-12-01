module Rester
  module Client::Adapters
    class HttpAdapter < Adapter
      autoload(:Connection, 'rester/client/adapters/http_adapter/connection')

      attr_reader :connection

      class << self
        def can_connect_to?(service)
          if service.is_a?(URI)
            uri = service
          elsif service.is_a?(String) && URI::regexp.match(service)
            uri = URI(service)
          end

          !!uri && ['http', 'https'].include?(uri.scheme)
        end
      end # Class Methods

      def connect(url)
        nil.tap { @connection = Connection.new(url, timeout: timeout) }
      end

      def connected?
        !!connection
      end

      def get!(path, params={})
        _require_connection
        _prepare_response(connection.get(path, headers: headers, query: params))
      end

      def delete!(path, params={})
        _require_connection
        _prepare_response(connection.delete(path, headers: headers, query: params))
      end

      def put!(path, params={})
        _require_connection
        _prepare_response(connection.put(path, headers: headers, data: params))
      end

      def post!(path, params={})
        _require_connection
        _prepare_response(connection.post(path, headers: headers, data: params))
      end

      private

      def _prepare_response(response)
        [response.code.to_i, response.body]
      end

      def _require_connection
        raise "not connected" unless connected?
      end
    end # HttpAdapter
  end # Client::Adapters
end # Rester
