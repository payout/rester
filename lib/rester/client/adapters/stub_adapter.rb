require 'yaml'
require 'json'
require 'pathname'

module Rester
  module Client::Adapters
    ##
    # An adapter to be used to stub the responses needed from specified service
    # requests via a yaml file. This will be used in spec tests to perform
    # "contractual testing"
    #
    # Note, this does not implement the "timeout" feature defined by the adapter
    # interface.
    class StubAdapter < Adapter
      attr_reader :stub

      class << self
        def can_connect_to?(service)
          service.is_a?(String) && Pathname(service).file?
        end
      end # Class Methods

      ##
      # Connects to the StubFile.
      def connect(stub_filepath)
        @stub = Utils::StubFile.new(stub_filepath)
      end

      def connected?
        !!stub
      end

      def request!(verb, path, encoded_data)
        params = Rack::Utils.parse_nested_query(encoded_data)
        _request(verb.to_s.upcase, path, params)
      end

      def with_context(context)
        @_context = context
        yield
        @_context = nil
      end

      private

      def _request(verb, path, params)
        spec = _process_request(path, verb, params)
        [spec['response_code'], spec['response'].to_json]
      end

      def _process_request(path, verb, params)
        fail Errors::StubError, "#{path} not found" unless stub[path]
        fail Errors::StubError, "#{verb} #{path} not found" unless stub[path][verb]

        context = @_context || _find_context_by_params(path, verb, params)

        unless (spec = stub[path][verb][context])
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' not found"
        end

        # Verify body, if there is one
        unless (request = spec['request']) == params
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' params don't match "\
            "stub. Expected: #{request} Got: #{params}"
        end

        # At this point, the 'request' is valid by matching a corresponding
        # request in the stub yaml file.
        stub[path][verb][context]
      end

      ##
      # Find the first request object with the same params as what's passed in.
      # Useful for testing without having to set the context.
      def _find_context_by_params(path, verb, params)
        (stub[path][verb].find { |_, spec| spec['request'] == params } || []
          ).first
      end
    end # StubAdapter
  end # Client::Adapters
end # Rester
