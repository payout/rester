module Rester
  module Utils
    class StubFile
      DEFAULT_TAGS = { 'successful' => 'true' }.freeze

      attr_reader :path

      def initialize(path)
        @path = path
        @_stub = StubFile.parse(path)
      end

      private

      def method_missing(meth, *args, &block)
        if @_stub.respond_to?(meth)
          @_stub.public_send(meth, *args, &block)
        else
          super
        end
      end

      ##
      # Class Methods
      class << self
        ##
        # Parses the stub file and returns the data as a hash
        def parse(path)
          parse!(YAML.load_file(path))
        end

        ##
        # Given a raw stub file hash, converts it to the format used internally.
        def parse!(stub_hash)
          stub_hash.each do |path, verbs|
            next if ['version', 'consumer', 'producer'].include?(path)

            verbs.each do |verb, contexts|
              contexts.each do |context, spec|
                _update_context(path, verb, context, spec)
              end
            end
          end
        end

        ##
        # Given a context hash, updates it for consumption by the rest of the
        # StubAdapter (i.e., removes tags from "response" key and puts them in
        # a "response_tags" key).
        def _update_context(path, verb, context, spec)
          _update_request(path, verb, context, spec)
          _update_response(path, verb, context, spec)
        end

        ##
        # Converts all the values in the request hash to strings, which mimics
        # how the data will be received on the service side.
        def _update_request(path, verb, context, spec)
          spec['request'] = Utils.stringify(spec['request'] || {})
        end

        ##
        # Parses response tags (e.g., response[successful=true]).
        #
        # Currently supported tags:
        #   successful    must be 'true' or 'false'
        def _update_response(path, verb, context, spec)
          responses = spec.select { |k,_|
            k =~ /\Aresponse(\[(\w+) *= *(\w+)(, *(\w+) *= *(\w+))*\])?\z/
          }

          if responses.count == 0
            fail Errors::StubError, "#{verb.upcase} #{path} is missing a " \
              "response for the context #{context.inspect}"
          elsif responses.count > 1
            fail Errors::StubError, "#{verb.upcase} #{path} has too many " \
              "responses defined for the context #{context.inspect}"
          end

          response_key = responses.keys.first

          tags = _parse_tags(path, verb, context, response_key)

          spec.merge!(
            'response' => spec.delete(response_key),
            'response_tags' => tags,
            'response_code' => _parse_response_code(verb, tags)
          )
        end

        ##
        # Takes a response key (e.g., "response[successful=false]") and parses out
        # the tags (e.g., {"successful" => false})
        def _parse_tags(path, verb, context, resp_key)
          DEFAULT_TAGS.merge(Hash[resp_key.scan(/(\w+) *= *(\w+)/)]).tap { |tags|
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

        def _parse_response_code(verb, tags)
          if tags['successful'] == 'true'
            (verb == 'POST') ? 201 : 200
          else
            400
          end
        end
      end # Class Methods
    end # StubFile
  end # Utils
end # Rester
