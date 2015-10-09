require 'stringio'

module Rester
  module Client::Adapters
    ##
    # An adapter for "connecting" to a service internally, without needing to
    # interface over a HTTP connection.
    class LocalAdapter < Adapter
      attr_reader :version
      attr_reader :service

      def connect(service, opts={})
        @version = opts[:version] || 1
        nil.tap { @service = service }
      end

      def connected?
        !!service
      end

      def get!(path, params={})
        _request(:get, path, headers: headers, query: params)
      end

      def delete!(path, params={})
        _request(:delete, path, headers: headers, query: params)
      end

      def put!(path, params={})
        _request(:put, path, headers: headers, data: params)
      end

      def post!(path, params={})
        _request(:post, path, headers: headers, data: params)
      end

      private

      def _request(verb, path, opts={})
        body = URI.encode_www_form(opts[:data] || {})
        query = URI.encode_www_form(opts[:query] || {})

        service.call(
          'REQUEST_METHOD' => verb.to_s.upcase,
          'PATH_INFO'      => "/v#{version}#{path}",
          'QUERY_STRING'   => query,
          'rack.input'     => StringIO.new(body)
        ).tap { |r| r.delete_at(1) }
      end
    end # LocalAdapter
  end # Client::Adapters
end # Rester
