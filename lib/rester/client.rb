require 'json'
require 'active_support/inflector'
require 'logger'

module Rester
  class Client
    autoload(:Adapters,   'rester/client/adapters')
    autoload(:Resource,   'rester/client/resource')
    autoload(:Response,   'rester/client/response')
    autoload(:Middleware, 'rester/client/middleware')

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
      self.logger = params[:logger]
      @_breaker_enabled = params.fetch(:circuit_breaker_enabled,
        ENV['RACK_ENV'] != 'test' && ENV['RAILS_ENV'] != 'test'
      )

      @_resource = Resource.new(self)
      _init_requester

      # Send a test ping request to the service so we can store the producer's
      # name for future request logs
      fail Errors::ConnectionError unless connected?
    end

    def connected?
      adapter.connected? && @_requester.call(:get, '/ping', {}).successful?
    rescue Exception => e
      logger.error("Connection Error: #{e.inspect}")
      false
    end

    def circuit_breaker_enabled?
      !!@_breaker_enabled
    end

    def logger=(logger)
      logger = Utils::LoggerWrapper.new(logger) if logger
      @logger = logger
    end

    def logger
      @logger || Rester.logger
    end

    def name
      @_producer_name
    end

    def request(verb, path, params={})
      path = _path_with_version(path)
      @_requester.call(verb, path, params)
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
    def _init_requester
      if circuit_breaker_enabled?
        @_requester = Utils::CircuitBreaker.new(
          threshold: error_threshold, retry_period: retry_period
        ) { |*args| _request(*args) }

        @_requester.on_open do
          logger.error("circuit opened for #{name}")
        end

        @_requester.on_close do
          logger.info("circuit closed for #{name}")
        end
      else
        @_requester = proc { |*args| _request(*args) }
      end
    end

    ##
    # Add a correlation ID to the header and send the request to the adapter
    def _request(verb, path, params)
      Rester.wrap_request do
        Rester.request_info[:producer_name] = name
        Rester.request_info[:path] = path
        Rester.request_info[:verb] = verb
        logger.info('sending request')

        _set_default_headers
        start_time = Time.now.to_f

        begin
          response = adapter.request(verb, path, params)
          _process_response(start_time, verb, path, *response)
        rescue Errors::TimeoutError
          logger.error('timed out')
          raise
        end
      end
    end

    def _set_default_headers
      adapter.headers(
        'X-Rester-Correlation-ID' => Rester.correlation_id,
        'X-Rester-Consumer-Name' => Rester.service_name,
        'X-Rester-Producer-Name' => name
      )
    end

    def _path_with_version(path)
      Utils.join_paths("/v#{version}", path)
    end

    def _process_response(start_time, verb, path, status, headers, body)
      elapsed_ms = (Time.now.to_f - start_time) * 1000
      response = Response.new(status, _parse_json(body))
      @_producer_name = headers['X-Rester-Producer-Name']
      logger.info("received status #{status} after %0.3fms" % elapsed_ms)

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
