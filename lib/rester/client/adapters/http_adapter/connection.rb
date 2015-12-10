require 'net/http'
require 'openssl'
require 'uri'

module Rester
  module Client::Adapters
    class HttpAdapter::Connection
      DEFAULT_DATA_HEADERS = {
        "Content-Type".freeze => "application/x-www-form-urlencoded".freeze
      }.freeze

      attr_reader :url
      attr_reader :timeout

      def initialize(url, opts={})
        @url = url.is_a?(String) ? URI(url) : url
        @url.path = @url.path[0..-2] if @url.path[-1] == '/'
        @timeout = opts[:timeout]
      end

      def request(verb, path, params={})
        _request(
          verb,
          _path(path, params[:query]),
          _headers(verb, params[:headers]),
          params[:data]
        )
      end

      private

      def _request(verb, path, headers, data)
        _http.public_send(verb, *[path, data, headers].compact)
      rescue Net::ReadTimeout, Net::OpenTimeout
        fail Errors::TimeoutError
      end

      def _path(path, query=nil)
        u = url.dup
        u.path = Utils.join_paths(u.path, path)
        u.query = query if query
        u.request_uri
      end

      def _headers(verb, headers)
        if [:post, :put].include?(verb)
          _prepare_data_headers(headers)
        else
          _prepare_headers(headers)
        end
      end

      def _prepare_data_headers(headers)
        DEFAULT_DATA_HEADERS.merge(_prepare_headers(headers))
      end

      def _http
        Net::HTTP.new(url.hostname, url.port).tap { |http|
          if (http.use_ssl=url.is_a?(URI::HTTPS))
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            http.cert_store = OpenSSL::X509::Store.new.tap { |s|
              s.set_default_paths
            }
          end

          http.open_timeout = http.read_timeout = timeout
        }
      end

      def _prepare_headers(headers)
        Hash[(headers || {}).map { |k, v| [k.to_s, v.to_s] }]
      end
    end # HttpAdapter::Connection
  end # Client::Adapters
end # Rester
