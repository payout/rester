require 'rester/version'
require 'rack'

module Rester
  require 'rester/railtie' if defined?(Rails)
  autoload(:Service,     'rester/service')
  autoload(:Errors,      'rester/errors')
  autoload(:Client,      'rester/client')
  autoload(:Utils,       'rester/utils')
  autoload(:Middleware,  'rester/middleware')

  class << self
    def load_tasks
      Dir[
        File.expand_path("../../tasks", __FILE__) + '/**.rake'
      ].each { |rake_file| load rake_file }
    end

    def connect(service, params={})
      klass = Client::Adapters.list.find { |a| a.can_connect_to?(service) }
      fail "unable to connect to #{service.inspect}" unless klass
      adapter = klass.new(service)
      Client.new(adapter, params)
    end
  end # Class Methods
end # Rester
