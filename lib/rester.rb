require 'rester/version'
require 'rack'
require 'pathname'

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
      elsif args.first.is_a?(String) && Pathname(args.first).file?
        unless (file_ext = Pathname(args.first).extname) == '.yml'
          raise Errors::InvalidStubFileError, "Expected .yml, got #{file_ext}"
        end
        Client.new(Client::Adapters::StubAdapter.new(*args))
      else
        Client.new(*args)
      end
    end
  end # Class Methods
end # Rester
