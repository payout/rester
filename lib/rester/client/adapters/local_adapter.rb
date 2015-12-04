require 'stringio'
require 'rack'
require 'timeout'

module Rester
  module Client::Adapters
    ##
    # An adapter for "connecting" to a service internally, without needing to
    # interface over a HTTP connection.
    class LocalAdapter < Adapter
      attr_reader :service

      class << self
        def can_connect_to?(service)
          service.is_a?(Class) && service < Service
        end
      end # Class Methods

      def connect(service)
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

      def _encode_data(data)
        Utils.encode_www_data(data) || ''
      end

      def _request(verb, path, opts={})
        body = _encode_data(opts[:data])
        query = _encode_data(opts[:query])

        response = Timeout::timeout(timeout) do
          service.call(
            'REQUEST_METHOD' => verb.to_s.upcase,
            'PATH_INFO'      => path,
            'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
            'QUERY_STRING'   => query,
            'rack.input'     => StringIO.new(body)
          )
        end

        body = response.last
        body = body.body if body.respond_to?(:body)
        body = body.join if body.respond_to?(:join)
        body = nil if body.respond_to?(:empty?) && body.empty?

        [
          response.first, # The status code
          body            # The response body.
        ]
      rescue Timeout::Error
        fail Errors::TimeoutError
      end
    end # LocalAdapter
  end # Client::Adapters
end # Rester
