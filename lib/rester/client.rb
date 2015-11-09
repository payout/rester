require 'json'
require 'active_support/inflector'

module Rester
  class Client
    autoload(:Adapters, 'rester/client/adapters')
    autoload(:Resource, 'rester/client/resource')

    attr_reader :adapter
    attr_reader :version

    def initialize(adapter, params={})
      self.adapter = adapter
      @version = params[:version] || 1
      @_resource = Resource.new(self)
    end

    def connect(*args)
      adapter.connect(*args)
    end

    def connected?
      adapter.connected? && adapter.get('/ping').first == 200
    end

    def request(verb, path, params={}, &block)
      path = _path_with_version(path)

      _process_response(path, *adapter.request(verb, path, params, &block))
    end

    ##
    # This is only implemented by the StubAdapter.
    def with_context(*args, &block)
      adapter.with_context(*args, &block)
    end

    protected

    def adapter=(adapter)
      @adapter = adapter
    end

    private

    ##
    # Submits the method to the adapter.
    def method_missing(meth, *args, &block)
      @_resource.send(:method_missing, meth, *args, &block)
    end

    def _path_with_version(path)
      Utils.join_paths("/v#{version}", path)
    end

    def _process_response(path, status, body)
      response = Response.new(status)

      if response.successful?
        response.merge!(_parse_json(body))
      elsif status == 400
        response[:error] = Errors::RequestError
        response[:message] = _parse_json(body)[:message]
      elsif status == 404
        response[:error] = Errors::NotFoundError
        response[:message] = "#{path}"
      else
        response[:error] = Errors::ServerError
        response[:message] = _parse_json(body)[:message]
      end

      response
    end

    def _parse_json(data)
      if data.is_a?(String) && !data.empty?
        JSON.parse(data, symbolize_names: true)
      else
        {}
      end
    end

    class Response < Hash
      def initialize(status)
        define_singleton_method(:status) { status }
      end

      def successful?
        status && status.between?(200, 299)
      end
    end # Response
  end # Client
end # Rester
