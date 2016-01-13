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
          service.is_a?(Class) && !!(service < Service)
        end
      end # Class Methods

      def connect(service)
        nil.tap { @service = service }
      end

      def connected?
        !!service
      end

      def request!(verb, path, encoded_data)
        data_key = [:get, :delete].include?(verb) ? :query : :data
        _request(verb, path, headers: headers, data_key => encoded_data)
      end

      private

      def _request(verb, path, opts={})
        body = opts[:data] || ''
        query = opts[:query] || ''

        response = Timeout::timeout(timeout) do
          service.call(
            {
              'REQUEST_METHOD' => verb.to_s.upcase,
              'PATH_INFO'      => path,
              'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
              'QUERY_STRING'   => query,
              'rack.input'     => StringIO.new(body)
              }.merge(opts[:headers])
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
