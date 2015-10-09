module Rester
  class Client
    module Adapters
      autoload(:Adapter,      'rester/client/adapters/adapter')
      autoload(:HttpAdapter,  'rester/client/adapters/http_adapter')
      autoload(:LocalAdapter, 'rester/client/adapters/local_adapter')
    end
  end
end
