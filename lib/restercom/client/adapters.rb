module Restercom
  class Client
    module Adapters
      autoload(:Adapter,     'restercom/client/adapters/adapter')
      autoload(:HttpAdapter, 'restercom/client/adapters/http_adapter')
    end
  end
end
