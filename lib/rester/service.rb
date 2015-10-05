require 'uri'
require 'rack'
require 'active_support/inflector'

module Rester
  class Service
    autoload(:Request, 'rester/service/request')
    autoload(:Object,  'rester/service/object')

    ##
    # The base set of middleware to use for every service.
    # Middleware will be executed in the order specified.
    BASE_MIDDLEWARE = [
      Rack::Head,
      Middleware::ErrorHandling,
      Middleware::StatusCheck
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

      def version_module(version)
        (@__version_modules ||= {})[version.to_sym] ||= _load_version_module(version)
      end

      def _load_version_module(version)
        versions.include?(version.to_sym) or
          raise ArgumentError, "invalid version #{version.inspect}"

        const_get(version.to_s.upcase)
      end

      def objects(version_module)
        (@__objects ||= {})[version_module] ||= _load_objects(version_module)
      end

      def _load_objects(version_module)
        version_module.constants.map { |c|
          version_module.const_get(c)
        }.select { |c|
          c.is_a?(Class) && c < Service::Object
        }
      end
    end # Class methods

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
      _process_request(Request.new(env))
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
    # Validates the request, calls the appropriate Service::Object method and
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
    # Calls the appropriate method on the appropriate Service::Object for the
    # request.
    def _call_method(request)
      params = request.params
      retval = nil

      name, id, *object_chain = request.object_chain
      obj = _load_object(request, name)

      loop {
        obj = obj.new(id) if id

        if object_chain.empty?
          retval = obj.process(request.request_method, params)
          break
        end

        params.merge!(obj.id_param => obj.id)
        name, id, *object_chain = object_chain
        obj = obj.mounts[name] or raise Errors::NotFoundError
      }

      retval
    end

    ##
    # Loads the appropriate Service::Object for the request. This will return
    # the class, not an instance.
    def _load_object(request, name)
      _version_module(request).const_get(name.camelcase.singularize)
    rescue NameError
      _error!(Errors::NotFoundError)
    end

    ##
    # Returns the module specified by the version in the request.
    def _version_module(request)
      self.class.version_module(request.version)
    end

    ##
    # Prepares the retval from a Service::Object method to be returned to the
    # client (i.e., validates it and dumps it as JSON).
    def _prepare_response(retval)
      retval ||= {}

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
