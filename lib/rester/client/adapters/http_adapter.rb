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

      def request!(verb, path, encoded_data)
        _require_connection

        data_key = [:get, :delete].include?(verb) ? :query : :data
        response = connection.request(verb, path,
          headers: headers, data_key => encoded_data)

        _prepare_response(response)
      end

      private

      def _prepare_response(response)
        # We want to format the header keys in the way we would expect it in our
        # client: X-Rester-Header-Key.
        #
        # http://ruby-doc.org/stdlib-2.1.1/libdoc/net/http/rdoc/Net/HTTPHeader.html
        headers = {}.tap { |h| response.each_capitalized { |k,v| h[k] = v } }
        [response.code.to_i, headers, response.body]
      end

      def _require_connection
        raise "not connected" unless connected?
      end
    end # HttpAdapter
  end # Client::Adapters
end # Rester
