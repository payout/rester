require 'net/http'
require 'openssl'
require 'uri'

module Restercom
  module Client::Adapters
    class HttpAdapter::Connection
      DEFAULT_POST_HEADERS = {
        "Content-Type".freeze => "application/x-www-form-urlencoded".freeze
      }.freeze

      attr_reader :url

      def initialize(url)
        @url = url.is_a?(String) ? URI(url) : url
        @url.path = @url.path[0..-2] if @url.path[-1] == '/'
      end

      def get(path, params={})
        _http.get(
          _path(path, params[:query]),
          _prepare_headers(params[:headers])
        )
      end

      def post(path, params={})
        headers = DEFAULT_POST_HEADERS.merge(_prepare_headers(params[:headers]))
        encoded_data = URI.encode_www_form(params[:data] || {})
        _http.post(_path(path), encoded_data, headers)
      end

      private

      def _path(path, query=nil)
        u = url.dup
        u.path += path
        u.query = URI.encode_www_form(query) if query && !query.empty?
        u.request_uri
      end

      def _http
        Net::HTTP.new(url.hostname, url.port).tap { |http|
          if (http.use_ssl=url.is_a?(URI::HTTPS))
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            http.cert_store = OpenSSL::X509::Store.new.tap { |s|
              s.set_default_paths
            }
          end
        }
      end

      def _prepare_headers(headers)
        Hash[(headers || {}).map { |k, v| [k.to_s, v.to_s] }]
      end
    end # HttpAdapter::Connection
  end # Client::Adapters
end # Restercom
