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

  # Set up the Client middleware if it's a Rails application
  if defined?(Rails) && Rails.application
    Rails.configuration.middleware.use(Client::Middleware::RequestHandler)
  end

  class << self
    def logger
      @_logger ||= Logger.new(STDOUT)
    end

    def logger=(new_logger)
      @_logger = new_logger
    end

    def load_tasks
      Dir[
        File.expand_path("../../tasks", __FILE__) + '/**.rake'
      ].each { |rake_file| load rake_file }
    end

    def connect(service, params={})
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

    def begin_request
      self.request_info = {}
    end

    def end_request
      self.request_info = nil
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
  end # Class Methods
end # Rester
