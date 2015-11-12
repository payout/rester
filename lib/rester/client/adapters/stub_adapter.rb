require 'yaml'
require 'json'
require 'pathname'

module Rester
  module Client::Adapters
    ##
    # An adapter to be used to stub the responses needed from specified service
    # requests via a yaml file. This will be used in spec tests to perform
    # "contractual testing"
    class StubAdapter < Adapter
      attr_reader :stub

      class << self
        def can_connect_to?(service)
          service.is_a?(String) && Pathname(service).file?
        end
      end # Class Methods

      def connect(stub_filepath, opts={})
        @stub = YAML.load_file(stub_filepath)
      end

      def connected?
        !!stub
      end

      def get!(path, params={})
        _request('GET', path, params)
      end

      def post!(path, params={})
        _request('POST', path, params)
      end

      def put!(path, params={})
        _request('PUT', path, params)
      end

      def delete!(path, params={})
        _request('DELETE', path, params)
      end

      def with_context(context, &block)
        @_context = context
        yield block
        @_context = nil
      end

      private

      def _request(verb, path, params)
        response = _process_request(path, verb, params)
        [response['code'], response['body'].to_json]
      end

      def _process_request(path, verb, params)
        fail Errors::StubError, "#{path} not found" unless stub[path]
        fail Errors::StubError, "#{verb} #{path} not found" unless stub[path][verb]

        context = @_context || _find_context_by_params(path, verb, params)

        unless (action = stub[path][verb][context])
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' not found"
        end

        # Verify body, if there is one
        unless (request = action['request'] || {}) == params
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' params don't match stub. Expected: #{request} Got: #{params}"
        end

        # At this point, the 'request' is valid by matching a corresponding
        # request in the stub yaml file. Grab the response from the file and
        # reset the context
        stub[path][verb][context]['response']
      end

      ##
      # Find the first request object with the same params as what's passed in.
      # Useful for testing without having to set the context.
      def _find_context_by_params(path, verb, params)
        (stub[path][verb].find { |_, action|
          (action['request'] || {}) == params
        } || []).first
      end
    end # StubAdapter
  end # Client::Adapters
end # Rester
