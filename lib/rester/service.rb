require 'uri'
require 'rack'
require 'active_support/inflector'
require 'logger'

module Rester
  class Service
    autoload(:Request,    'rester/service/request')
    autoload(:Resource,   'rester/service/resource')
    autoload(:Middleware, 'rester/service/middleware')

    attr_reader :logger

    ##
    # The base set of middleware to use for every service.
    # Middleware will be executed in the order specified.
    BASE_MIDDLEWARE = [
      Rack::Head,
      Middleware::RequestHandler,
      Middleware::ErrorHandling,
      Middleware::Ping
    ].freeze

    ########################################################################
    # DSL
    ########################################################################
    class << self
      ###
      # Middleware DSL
      ###

      def use(klass, *args)
        _middleware << [klass, *args]
      end

      def _middleware
        @__middleware ||= BASE_MIDDLEWARE.dup
      end
    end # DSL

    ########################################################################
    # Class Methods
    ########################################################################
    class << self
      def instance
        @instance ||= new
      end

      # The call method needs to call the rack_call method, which adds additional
      # rack middleware.
      def call(env)
        instance.rack_call(env)
      end

      def method_missing(meth, *args, &block)
        instance.public_send(meth, *args, &block)
      end

      def versions
        @__versions ||= constants.map(&:to_s).select { |c|
          c.match(/^V\d{1,3}$/)
        }.map(&:downcase).map(&:to_sym)
      end

      def service_name
        @__name ||= (name && name.split('::').last) || 'Anonymous'
      end

      def version_module(version)
        (@__version_modules ||= {})[version.to_sym] ||= _load_version_module(version)
      end

      def _load_version_module(version)
        versions.include?(version.to_sym) or
          raise ArgumentError, "invalid version #{version.inspect}"

        const_get(version.to_s.upcase)
      end

      def resources(version_module)
        (@__resources ||= {})[version_module] ||= _load_resources(version_module)
      end

      def _load_resources(version_module)
        version_module.constants.map { |c|
          version_module.const_get(c)
        }.select { |c|
          c.is_a?(Class) && c < Service::Resource
        }
      end
    end # Class methods

    def logger
      @_logger || Rester.logger
    end

    def logger=(new_logger)
      new_logger = Utils::LoggerWrapper.new(new_logger) if new_logger
      @_logger = new_logger
    end

    def name
      self.class.service_name
    end

    ##
    # To be called by Rack. Wraps the app in middleware.
    def rack_call(env)
      _rack_app.call(env)
    end

    ##
    # Call the service app directly.
    #
    # Duplicates the instance before processing the request so individual requests
    # can't impact each other.
    def call(env)
      dup.call!(env)
    end

    ##
    # Process the request.
    #
    # Calls methods that may modify instance variables, so the instance should
    # be dup'd beforehand.
    def call!(env)
      _process_request(Rester.request)
    end

    private

    def _rack_app
      @__rack_app ||= _build_rack_app
    end

    def _build_rack_app
      Rack::Builder.new.tap { |app|
        self.class._middleware.each { |m| app.use(*m) }
        app.run self
      }.to_app
    end

    ##
    # Validates the request, calls the appropriate Service::Resource method and
    # returns a valid Rack response.
    def _process_request(request)
      _error!(Errors::NotFoundError) unless request.valid?
      _validate_version(request)
      retval = _call_method(request)
      _response(request.post? ? 201 : 200, _prepare_response(retval))
    end

    ##
    # Validates that the version of the request matches a defined version module.
    # If the version is not found, it throws a NotFoundError (HTTP 404).
    def _validate_version(request)
      unless self.class.versions.include?(request.version)
        _error!(Errors::NotFoundError, request.version)
      end
    end

    ##
    # Calls the appropriate method on the appropriate Service::Resource for the
    # request.
    def _call_method(request)
      params = request.params
      resource_obj = nil
      resource_id = nil

      request.each_resource do |name, id|
        unless resource_obj
          (resource_obj = _load_resource(request.version, name)) or
            _error!(Errors::NotFoundError)
        else
          mounted_resource = resource_obj.mounts[name] or
            _error!(Errors::NotFoundError)
          resource_obj = mounted_resource.new
        end

        params.merge!(resource_obj.id_param => id) if id
        resource_id = id
      end

      resource_obj.process(request.request_method, !!resource_id, params)
    end

    ##
    # Loads the appropriate Service::Resource for the request. This will return
    # the class, not an instance.
    def _load_resource(version, name)
      _version_module(version).const_get(name.camelcase.singularize).new
    rescue NameError
      nil
    end

    ##
    # Returns the module specified by the version in the request.
    def _version_module(version)
      self.class.version_module(version)
    end

    ##
    # Prepares the retval from a Service::Resource method to be returned to the
    # client (i.e., validates it and dumps it as JSON).
    def _prepare_response(retval)
      unless retval.is_a?(Hash)
        _error!(Errors::ServerError, "Invalid response: #{retval.inspect}")
      end

      JSON.dump(retval)
    end

    ##
    # Returns a valid rack response.
    def _response(status, body=nil, headers={})
      body = [body].compact
      headers = headers.merge("Content-Type" => "application/json")
      Rack::Response.new(body, status, headers).finish
    end

    ##
    # Throws an exception (instead of raising it). This is done for performance
    # reasons. The exception will be caught in the ErrorHandling middleware.
    def _error!(klass, message=nil)
      Errors.throw_error!(klass, message)
    end
  end # Service
end # Rester
