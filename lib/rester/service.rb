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

    # Used to signify an empty body
    class EmptyResponse; end

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

    attr_reader :request

    def initialize(opts={})
      @_opts = opts.dup
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
    # Actually process the request.
    #
    # Calls methods that may modify instance variables, so the instance should
    # be dup'd beforehand.
    def call!(env)
      @request = Request.new(env)
      _process_request
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

    def _process_request
      _error!(Errors::NotFoundError) unless request.valid?
      _validate_version
      retval = _resolve_object_chain
      _response(request.post? ? 201 : 200, _prepare_response(retval))
    end

    def _resolve_object_chain
      params = request.params
      retval = nil

      name, id, *object_chain = request.object_chain
      obj = _load_object(name)

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

    def _version_module
      self.class.version_module(request.version)
    end

    def _load_object(name)
      _version_module.const_get(name.camelcase.singularize)
    rescue NameError
      _error!(Errors::NotFoundError)
    end

    def _validate_version
      unless self.class.versions.include?(request.version)
        _error!(Errors::NotFoundError)
      end
    end

    def _prepare_response(retval)
      retval ||= {}

      unless retval.is_a?(Hash)
        _error!(Errors::ServerError, "Invalid response: #{retval.inspect}")
      end

      JSON.dump(retval)
    end

    def _parse_path
      path = request.path
      uri = URI(path)
      uri.path.split('/')[1..-1]
    end

    def _parse_params
      if request.get?
        request.GET
      elsif request.post?
        request.POST
      end
    end

    def _response(status, body=EmptyResponse, headers={})
      body = body == EmptyResponse ? [] : [body]
      headers = headers.merge("Content-Type" => "application/json")
      Rack::Response.new(body, status, headers).finish
    end

    def _error!(klass, message=nil)
      Errors.throw_error!(klass, message)
    end
  end # Service
end # Rester
