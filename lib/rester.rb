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

    def connect(*args)
      Client.new(*args)
    end
  end # Class Methods
end # Rester