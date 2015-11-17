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
        @stub = _parse_file(stub_filepath)
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

      def with_context(context)
        @_context = context
        yield
        @_context = nil
      end

      private

      ##
      # Loads the stub file as a YAML file and parses out any response tags
      # (e.g., 'response[successful=false, tag=value')
      def _parse_file(path)
        stub = YAML.load_file(path)

        stub.each do |path, verbs|
          next if ['version', 'consumer', 'producer'].include?(path)

          verbs.each do |verb, contexts|
            contexts.each do |context, spec|
              _update_context(path, verb, context, spec)
            end
          end
        end

        stub
      end

      ##
      # Given a context hash, updates it for consumption by the rest of the
      # StubAdapter (i.e., removes tags from "response" key and puts them in
      # a "response_tags" key).
      def _update_context(path, verb, context, spec)
        responses = spec.select { |k,_|
          k =~ /\Aresponse(\[(\w+) *= *(\w+)(, *(\w+) *= *(\w+))*\])?\z/
        }

        if responses.count == 0
          fail Errors::StubError, "#{verb.upcase} #{path} is missing a " \
            "response for the context #{context.inspect}"
        elsif responses.count > 1
          fail Errors::StubError, "#{verb.upcase} #{path} has too many" \
            "responses defined for the context #{context.inspect}"
        end

        response_key = responses.keys.first

        spec.merge!(
          'response' => spec.delete(response_key),
          'response_tags' => _parse_tags(path, verb, context, response_key)
        )
      end

      DEFAULT_TAGS = { 'successful' => 'true' }.freeze

      ##
      # Takes a response key (e.g., "response[successful=false]") and parses out
      # the tags (e.g., {"successful" => false})
      def _parse_tags(path, verb, context, resp_key)
        DEFAULT_TAGS.merge(resp_key.scan(/(\w+) *= *(\w+)/).to_h).tap { |tags|
          _validate_tags(path, verb, context, tags)
        }
      end

      def _validate_tags(path, verb, context, tags)
        unless ['true', 'false'].include?(tags['successful'])
          fail Errors::StubError, '"successful" tag should be either "true" '\
            'or "false" in' "#{verb.upcase} #{path} in context " \
            "#{context.inspect}"
        end
      end

      def _request(verb, path, params)
        context = _process_request(path, verb, params)

        if context['response_tags']['successful'] == 'true'
          code = (verb == 'POST') ? 201 : 200
        else
          code = 400
        end

        [code, context['response'].to_json]
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
        unless (request = Utils.stringify_vals(action['request'] || {})) == params
          fail Errors::StubError,
            "#{verb} #{path} with context '#{context}' params don't match stub. Expected: #{request} Got: #{params}"
        end

        # At this point, the 'request' is valid by matching a corresponding
        # request in the stub yaml file.
        stub[path][verb][context]
      end

      ##
      # Find the first request object with the same params as what's passed in.
      # Useful for testing without having to set the context.
      def _find_context_by_params(path, verb, params)
        (stub[path][verb].find { |_, action|
          (Utils.stringify_vals(action['request'] || {})) == params
        } || []).first
      end
    end # StubAdapter
  end # Client::Adapters
end # Rester
