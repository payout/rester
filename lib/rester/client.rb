require 'json'
require 'active_support/inflector'
require 'logger'

module Rester
  class Client
    autoload(:Adapters, 'rester/client/adapters')
    autoload(:Resource, 'rester/client/resource')
    autoload(:Response, 'rester/client/response')

    attr_reader :adapter
    attr_reader :version
    attr_reader :error_threshold
    attr_reader :retry_period
    attr_reader :logger

    def initialize(adapter, params={})
      self.adapter = adapter
      self.version = params[:version]
      @error_threshold = (params[:error_threshold] || 3).to_i
      @retry_period = (params[:retry_period] || 1).to_f
      @logger = params[:logger] || Logger.new(STDOUT)

      @_resource = Resource.new(self)
      _init_request_breaker
    end

    def connect(*args)
      adapter.connect(*args)
    end

    def connected?
      adapter.connected? && adapter.get('/ping').first == 200
    end

    def request(verb, path, params={})
      @_request_breaker.call(verb, path, params)
    rescue Utils::CircuitBreaker::CircuitOpenError
      # Translate this error so it's easier handle for clients.
      # Also, at some point we may want to extract CircuitBreaker into its own
      # gem, and this will make that easier.
      raise Errors::CircuitOpenError
    end

    ##
    # This is only implemented by the StubAdapter.
    def with_context(*args, &block)
      adapter.with_context(*args, &block)
    end

    protected

    def adapter=(adapter)
      @adapter = adapter
    end

    def version=(version)
      unless (@version = (version || 1).to_i) > 0
        fail ArgumentError, 'version must be > 0'
      end
    end

    private

    ##
    # Submits the method to the adapter.
    def method_missing(meth, *args, &block)
      @_resource.send(:method_missing, meth, *args, &block)
    end

    ##
    # Sets up the circuit breaker for making requests to the service.
    #
    # Any exception raised by the `_request` method will count as a failure for
    # the circuit breaker.  Once the threshold for errors has been reached, the
    # circuit opens and all subsequent requests will raise a CircuitOpenError.
    #
    # When the circuit is opened or closed, a message is sent to the logger for
    # the client.
    def _init_request_breaker
      @_request_breaker = Utils::CircuitBreaker.new(
        threshold: error_threshold, retry_period: retry_period
      ) { |v, p, pm| _request(v, p, pm) }

      @_request_breaker.on_open do
        logger.error("circuit opened")
      end

      @_request_breaker.on_close do
        logger.info("circuit closed")
      end
    end

    def _request(verb, path, params)
      path = _path_with_version(path)
      _process_response(path, *adapter.request(verb, path, params))
    end

    def _path_with_version(path)
      Utils.join_paths("/v#{version}", path)
    end

    def _process_response(path, status, body)
      response = Response.new(status, _parse_json(body))

      unless [200, 201, 400].include?(status)
        case status
        when 401
          fail Errors::AuthenticationError
        when 403
          fail Errors::ForbiddenError
        when 404
          fail Errors::NotFoundError, path
        else
          fail Errors::ServerError, response[:message]
        end
      end

      response
    end

    def _parse_json(data)
      if data.is_a?(String) && !data.empty?
        JSON.parse(data, symbolize_names: true)
      else
        {}
      end
    end
  end # Client
end # Rester
