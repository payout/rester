require 'uri'
require 'rack'

module Rester
  class Service
    ##
    # The base set of middleware to use for every service.
    # Middleware will be executed in the order specified.
    BASE_MIDDLEWARE = [
      Rack::Head,
      Middleware::ErrorHandling
    ].freeze

    # Used to signify an empty body
    class EmptyResponse; end

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

      ###
      # Middleware DSL
      ###

      def use(klass, *args)
        _middleware << [klass, *args]
      end

      def _middleware
        @__middleware ||= BASE_MIDDLEWARE.dup
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
      @request = Rack::Request.new(env)
      _process_request
    end

    ##
    # Built in service method called by Client#connected?
    def test_connection(params={})
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
      error!(Errors::NotFoundError) unless request.get? || request.post?
      method, *args = _parse_path
      params = _parse_params
      method = "#{method}!" if request.post?
      retval = public_send(method, *args, params)
      _response(request.post? ? 201 : 200, _prepare_response(retval))
    end

    def _prepare_response(retval)
      retval ||= {}

      unless retval.is_a?(Hash)
        error!(Errors::ServerError, "Invalid response: #{retval.inspect}")
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
