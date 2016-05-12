require 'rester/version'
require 'rack'
require 'securerandom'
require 'active_support/core_ext/class/subclasses'

module Rester
  require 'rester/railtie' if defined?(Rails)
  autoload(:Service,     'rester/service')
  autoload(:Errors,      'rester/errors')
  autoload(:Client,      'rester/client')
  autoload(:Utils,       'rester/utils')
  autoload(:Middleware,  'rester/middleware')

  @_request_infos ||= ThreadSafe::Cache.new

  class << self
    def logger
      @_logger ||= Utils::LoggerWrapper.new
    end

    def logger=(new_logger)
      @_logger = Utils::LoggerWrapper.new(new_logger)
    end

    def load_tasks
      Dir[
        File.expand_path("../../tasks", __FILE__) + '/**.rake'
      ].each { |rake_file| load rake_file }
    end

    def connect(service, params = {})
      _install_middleware_if_needed
      adapter_opts = Client::Adapters.extract_opts(params)
      adapter = Client::Adapters.connect(service, adapter_opts)
      Client.new(adapter, params)
    end

    def service_name
      @_service_name ||= _get_service_name
    end

    def service_name=(name)
      @_service_name = name
    end

    ##
    # Used to manage the thread-safe `Rester.request_info` object.
    def wrap_request
      outer_most = !request_info

      self.request_info = {} if outer_most
      yield
    ensure
      self.request_info = nil if outer_most
    end

    def processing_request?
      !!request_info
    end

    def request_info
      @_request_infos[Thread.current.object_id]
    end

    def request_info=(info)
      if info.nil?
        @_request_infos.delete(Thread.current.object_id)
      else
        @_request_infos[Thread.current.object_id] = info
      end
    end

    def request
      request_info[:request]
    end

    def request=(request)
      request_info[:request] = request
    end

    def correlation_id
      request_info && request_info[:correlation_id]
    end

    def correlation_id=(correlation_id)
      request_info[:correlation_id] = correlation_id
    end

    private

    def _get_service_name
      if defined?(Rails) && Rails.application
        Rails.application.class.parent_name
      else
        services = Service.descendants
        fail "Define a service name" if services.empty?
        services.first.service_name
      end
    end

    ##
    # On the first call, installs the Client RequestHandler middleware into the
    # host application. Subsequent calls will do nothing.
    def _install_middleware_if_needed
      return if @__middleware_installed
      @__middleware_installed = true

      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        Rails.configuration.middleware.use(Client::Middleware::RequestHandler)
      end
    end
  end # Class Methods
end # Rester
