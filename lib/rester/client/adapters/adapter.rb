module Rester
  module Client::Adapters
    class Adapter
      class << self
        ##
        # Returns whether or not the Adapter can connect to the service
        def can_connect_to?(service)
          raise NotImplementedError
        end
      end # Class Methods

      attr_reader :timeout

      def initialize(service=nil, opts={})
        @timeout = opts[:timeout]
        connect(service) if service
      end

      ##
      # Returns the headers defined for this Adapter. Optionally, you may also
      # define additional headers you'd like to add/override.
      def headers(new_headers={})
        (@headers ||= {}).merge!(new_headers)
      end

      ##
      # Connect to a service. The specific arguments depend on the Adapter
      # subclass.
      def connect(*args)
        raise NotImplementedError
      end

      ##
      # Returns whether or not the Adapter is connected to a service.
      def connected?
        raise NotImplementedError
      end

      def request(verb, path, params={})
        params ||= {}
        _validate_verb(verb)
        params = _validate_params(params)
        public_send("#{verb}!", path.to_s, params)
      end

      [:get, :post, :put, :delete].each do |verb|
        ##
        # Define helper methods: get, post, put, delete
        define_method(verb) { |*args|
          request(verb, *args)
        }

        ##
        # Define implementation methods: get!, post!, put!, delete!
        # These methods should be overridden by the specific adapter.
        define_method("#{verb}!") { |*args|
          raise NotImplementedError
        }
      end

      protected

      def headers=(h)
        @headers = h
      end

      private

      VALID_VERBS = {
        get:    true,
        post:   true,
        put:    true,
        delete: true
      }.freeze

      ##
      # PARAM_KEY_TRANSFORMERS
      #
      # Defines how to transform a key value before being sent to the server.
      # At the moment, this is a simple to_s conversion.
      PARAM_KEY_TRANSFORMERS = Hash.new { |_, key|
        proc { |value|
          fail ArgumentError, "Invalid param key type: #{key.inspect}"
        }
      }.merge(
        String   => :to_s.to_proc,
        Symbol   => :to_s.to_proc
      ).freeze

      ##
      # PARAM_VALUE_TRANSFORMERS
      #
      # Defines how values should be transformed before being sent to the
      # server. Mostly, this is just a simple conversion to a string, but in
      # the case of `nil` we want to convert it to 'null'.
      PARAM_VALUE_TRANSFORMERS = Hash.new { |_, key|
        proc { |value|
          fail ArgumentError, "Invalid param value type: #{key.inspect}"
        }
      }.merge(
        String     => :to_s.to_proc,
        Symbol     => :to_s.to_proc,
        Fixnum     => :to_s.to_proc,
        Integer    => :to_s.to_proc,
        Float      => :to_s.to_proc,
        DateTime   => :to_s.to_proc,
        TrueClass  => :to_s.to_proc,
        FalseClass => :to_s.to_proc,
        NilClass   => proc { 'null' }
      ).freeze

      def _validate_verb(verb)
        VALID_VERBS[verb] or
          raise ArgumentError, "Invalid verb: #{verb.inspect}"
      end

      def _validate_params(params)
        params.map { |key, value|
          [
            PARAM_KEY_TRANSFORMERS[key.class].call(key),
            PARAM_VALUE_TRANSFORMERS[value.class].call(value)
          ]
        }.to_h
      end
    end # Adapter
  end # Client::Adapters
end # Rester
