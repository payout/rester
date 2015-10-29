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

      def self.can_connect_to?(service)
        service.is_a?(String) && Pathname(service).file?
      end

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

      def context
        @_context
      end

      def context=(context)
        @_context = context
      end

      private

      def _request(verb, path, params)
        _validate_request(verb, path, params)

        # At this point, the 'request' is valid by matching a corresponding request
        # in the stub yaml file. Grab the response from the file and reset the context
        response = stub[path][verb][context]['response']
        context = nil
        [response['code'], JSON.parse(response['body']).to_json]
      end

      def _validate_request(verb, path, params)
        raise Errors::ValidationError, "#{path} not found" unless stub[path]
        raise Errors::ValidationError, "#{verb} #{path} not found" unless stub[path][verb]

        unless (action = stub[path][verb][context])
          raise Errors::ValidationError,
            "#{verb} #{path} with context '#{context}' not found"
        end

        # Verify body, if there is one
        if (request = action['request'])
          stub_params = JSON.parse(request['body'], symbolize_names: true)
          unless stub_params == params
            raise Errors::ValidationError,
              "#{verb} #{path} with context '#{context}' params don't match stub"
          end
        end
      end
    end # StubAdapter
  end # Client::Adapters
end # Rester