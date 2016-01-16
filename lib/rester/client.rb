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
      @logger = params[:logger] || Rester.logger
      @_breaker_enabled = params.fetch(:circuit_breaker_enabled,
        ENV['RACK_ENV'] != 'test' && ENV['RAILS_ENV'] != 'test'
      )


      @_resource = Resource.new(self)
      _init_requester
    end

    def connect(*args)
      adapter.connect(*args)
    end

    def connected?
      adapter.connected? && adapter.get('/ping').first == 200
    end

    def circuit_breaker_enabled?
      !!@_breaker_enabled
    end

    def request(verb, path, params={})
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
          _log_with_correlation_id(:error, "circuit opened for #{_producer_name}")
        end

        @_requester.on_close do
          _log_with_correlation_id(:info, "circuit closed for #{_producer_name}")
        end
      else
        @_requester = proc { |*args| _request(*args) }
      end
    end

    ##
    # Add a correlation ID to the header and send the request to the adapter
    def _request(verb, path, params)
      path = _path_with_version(path)
      _set_default_headers
      _log_req_res(:request, verb, path)
      _process_response(verb, path, *adapter.request(verb, path, params))
    end

    def _set_default_headers
      adapter.headers(
        'X-Rester-Correlation-ID' => Rester.correlation_id,
        'X-Rester-Consumer-Name' => Rester.service_name,
        'X-Rester-Producer-Name' => _producer_name
      )
    end

    def _producer_name
      @_producer_name ||= "Producer"
    end

    def _path_with_version(path)
      Utils.join_paths("/v#{version}", path)
    end

    def _process_response(verb, path, status, body, headers={})
      response = Response.new(status, _parse_json(body))
      @_producer_name = headers['http_x_rester_producer_name'] &&
        headers['http_x_rester_producer_name'].first

      _log_req_res(:response, verb, path, status)

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

    def _log_req_res(type, verb, path, status=nil)
      arrow_str = type == :request ? '->' : '<-'
      log_str = "[#{Rester.service_name}] #{arrow_str} #{_producer_name} - " \
        "#{verb.upcase} #{path}"
      log_str << " #{status}" if status
      _log_with_correlation_id(:info, log_str)
    end

    def _log_with_correlation_id(log_level, msg)
      logger.send(log_level, "Correlation-ID=#{Rester.correlation_id}: #{msg}")
    end
  end # Client
end # Rester
