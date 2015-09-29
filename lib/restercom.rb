require 'restercom/version'
require 'rack'

module Restercom
  require 'restercom/railtie' if defined?(Rails)
  autoload(:Service,     'restercom/service')
  autoload(:Errors,      'restercom/errors')
  autoload(:Client,      'restercom/client')
  autoload(:Utils,       'restercom/utils')
  autoload(:Middleware,  'restercom/middleware')

  class << self
    def load_tasks
      Dir[
        File.expand_path("../../tasks", __FILE__) + '/**.rake'
      ].each { |rake_file| load rake_file }
    end

    def connect(*args)
      Client.new(*args)
    end
  end # Class Methods
end # Restercom
