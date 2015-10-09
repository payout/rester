require 'json'
require 'active_support/inflector'

module Rester
  class Client
    autoload(:Adapters, 'rester/client/adapters')
    autoload(:Resource, 'rester/client/resource')

    attr_reader :adapter

    def initialize(*args)
      case args.first
      when Adapters::Adapter
        self.adapter = args.first
      else
        self.adapter = Adapters::HttpAdapter.new(*args)
      end

      @_resource = Resource.new(self)
    end

    def connect(*args)
      adapter.connect(*args)
    end

    def connected?
      adapter.connected? && adapter.get('status').first == 200
    end

    def request(verb, path, params={}, &block)
      _process_response(path, *adapter.request(verb, path, params, &block))
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

    def _process_response(path, status, body)
      if status.between?(200, 299)
        _parse_json(body)
      elsif status == 400
        raise Errors::RequestError, _parse_json(body)[:message]
      elsif status == 404
        raise Errors::NotFoundError, "/#{path}"
      else
        raise Errors::ServerError, _parse_json(body)[:message]
      end
    end

    def _parse_json(data)
      if data.is_a?(String) && !data.empty?
        JSON.parse(data, symbolize_names: true)
      else
        {}
      end
    end
  end # Client
end # Rester
