require 'json'

module Rester
  class Client
    autoload(:Adapters, 'rester/client/adapters')

    attr_reader :adapter

    def initialize(*args)
      case args.first
      when Adapters::Adapter
        self.adapter = args.first
      else
        self.adapter = Adapters::HttpAdapter.new(*args)
      end
    end

    def connect(*args)
      adapter.connect(*args)
    end

    def connected?
      adapter.connected? && adapter.get(:test_connection).first == 200
    end

    protected

    def adapter=(adapter)
      @adapter = adapter
    end

    private

    ##
    # Submits the method to the adapter.
    def method_missing(meth, *args, &block)
      verb, meth = Utils.extract_method_verb(meth)
      _process_response(meth, *adapter.request(verb, meth, *args, &block))
    end

    def _process_response(meth, status, body)
      if status.between?(200, 299)
        _parse_json(body)
      elsif status == 400
        raise Errors::RequestError, _parse_json(body)[:message]
      elsif status == 404
        raise Errors::InvalidMethodError, meth.to_s
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
