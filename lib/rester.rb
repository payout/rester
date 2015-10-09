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
      if (service = args.first).is_a?(Class) && service < Service
        Client.new(Client::Adapters::LocalAdapter.new(*args))
      else
        Client.new(*args)
      end
    end
  end # Class Methods
end # Rester
