module Rester
  module Client::Adapters
    class Adapter
      def initialize(*args)
        connect(*args) unless args.empty?
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

      def request(verb, path, params={}, &block)
        params ||= {}
        _validate_verb(verb)
        _validate_params(params)
        public_send("#{verb}!", path.to_s, params)
      end

      [:get, :post, :put, :delete].each do |verb|
        ##
        # Define helper methods: get, post, put, delete
        define_method(verb) { |*args, &block|
          request(verb, *args, &block)
        }

        ##
        # Define implementation methods: get!, post!, put!, delete!
        # These methods should be overridden by the specific adapter.
        define_method("#{verb}!") { |*args, &block|
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

      VALID_ARG_TYPES = {
        String  => true,
        Symbol  => true,
        Fixnum  => true,
        Integer => true,
        Float   => true
      }.freeze

      VALID_PARAM_KEY_TYPES = {
        String   => true,
        Symbol   => true
      }.freeze

      VALID_PARAM_VALUE_TYPES = {
        String   => true,
        Symbol   => true,
        Fixnum   => true,
        Integer  => true,
        Float    => true,
        DateTime => true
      }.freeze

      def _validate_verb(verb)
        VALID_VERBS[verb] or
          raise ArgumentError, "Invalid verb: #{verb.inspect}"
      end

      def _validate_args(args)
        args.each { |arg|
          VALID_ARG_TYPES[arg.class] or
            raise ArgumentError, "Invalid argument type: #{arg.inspect}"
        }
      end

      def _validate_params(params)
        params.each { |key, value|
          VALID_PARAM_KEY_TYPES[key.class] or
            raise ArgumentError, "Invalid param key type: #{key.inspect}"

          VALID_PARAM_VALUE_TYPES[value.class] or
            raise ArgumentError, "Invalid param value type: #{value.inspect}"
        }
      end
    end # Adapter
  end # Client::Adapters
end # Rester
