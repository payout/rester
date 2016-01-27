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

      def initialize(service = nil, opts = {})
        @timeout = opts[:timeout]
        connect(service) if service
      end

      ##
      # Returns the headers defined for this Adapter. Optionally, you may also
      # define additional headers you'd like to add/override.
      def headers(new_headers = {})
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

      ##
      # Sends a request (using one of the subclass adapters) to the service.
      #
      # `params` should be a hash if specified.
      def request(verb, path, params = nil)
        _validate_verb(verb)
        request!(verb, path.to_s, Utils.encode_www_data(params))
      end

      ##
      # Sends an HTTP request to the service.
      #
      # `encoded_data` should be URL encoded set of parameters
      # (e.g., "key1=value1&key2=value2")
      def request!(verb, path, encoded_data)
        fail NotImplementedError
      end

      [:get, :post, :put, :delete].each do |verb|
        ##
        # Define helper methods: get, post, put, delete
        define_method(verb) { |*args|
          request(verb, *args)
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

      def _validate_verb(verb)
        VALID_VERBS[verb] or
          fail ArgumentError, "Invalid verb: #{verb.inspect}"
      end
    end # Adapter
  end # Client::Adapters
end # Rester
