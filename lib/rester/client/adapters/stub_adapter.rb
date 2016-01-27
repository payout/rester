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

      def producer
        stub['producer']
      end

      def request!(verb, path, encoded_data)
        if verb == :get && path == '/ping'
          return [200, { 'X-Rester-Producer-Name' => producer }, '']
        end

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
        [
          spec['response_code'],
          { 'X-Rester-Producer-Name' => producer },
          spec['response'].to_json
        ]
      end

      def _process_request(path, verb, params)
        unless stub[path]
          fail Errors::StubError, "#{path} not found"
        end

        unless stub[path][verb]
          fail Errors::StubError, "#{verb} #{path} not found"
        end

        context = @_context || _find_context_by_params(path, verb, params)

        unless (spec = stub[path][verb][context])
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' not found"
        end

        # Verify request params. Compile a list of mismatched params values and
        # any incoming request param keys which aren't specified in the stub
        unless (spec_params = spec['request']) == params
          diff = _param_diff(params, spec_params)
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' params don't match "\
            "stub: #{diff}"
        end

        # At this point, the 'request' is valid by matching a corresponding
        # request in the stub yaml file.
        stub[path][verb][context]
      end

      ##
      # Generate the diff string in the case when the request params of the
      # service don't match the params specified in the stub file.
      def _param_diff(params, spec_params)
        params = params.dup
        # Compile a list of mismatched params values
        diff = spec_params.map { |k,v|
          param_value = params.delete(k)
          unless v == param_value
            "#{k.inspect} should equal #{v.inspect} but got "\
              "#{param_value.inspect}"
          end
        }.compact.join(', ')

        unless params.empty?
          # Add any param keys which aren't specified in the spec
          diff << ', and ' unless diff.empty?
          unexpected_str = params.keys.map(&:to_s).map(&:inspect).join(', ')
          diff << "received unexpected key(s): #{unexpected_str}"
        end

        diff
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
