require 'rester/version'
require 'rack'

module Rester
  require 'rester/railtie' if defined?(Rails)
  autoload(:Service,     'rester/service')
  autoload(:Errors,      'rester/errors')
  autoload(:Client,      'rester/client')
  autoload(:Utils,       'rester/utils')
  autoload(:Middleware,  'rester/middleware')

  @_correlation_ids ||= ThreadSafe::Cache.new

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

    def consumer_name
      @_consumer_name ||= defined?(Rails) ? Rails.application.class.parent_name
        : "Consumer"
    end

    def consumer_name=(name)
      @_consumer_name = name
    end

    def correlation_id
      _correlation_ids[Thread.current.object_id] ||= SecureRandom.uuid
    end

    def correlation_id=(id)
      if id.nil?
        _correlation_ids.delete(Thread.current.object_id)
      else
        _correlation_ids[Thread.current.object_id] = id
      end
    end

    private

    def _correlation_ids
      @_correlation_ids
    end
  end # Class Methods
end # Rester
