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

      def request(verb, method, *args, &block)
        _validate_verb(verb)
        params = _validate_params(args.pop) if args.last.is_a?(Hash)
        _validate_args(args)

        public_send(
          "#{verb}!",
          "/#{method}/#{args.map(&:to_s).join('/')}",
          params
        )
      end

      def get(method, *args, &block)
        request(:get, method, *args, &block)
      end

      def post(method, *args, &block)
        request(:post, method, *args, &block)
      end

      def get!(path, params={})
        raise NotImplementedError
      end

      def post!(path, params={})
        raise NotImplementedError
      end

      protected

      def headers=(h)
        @headers = h
      end

      private

      VALID_VERBS = {
        get: true,
        post: true
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
