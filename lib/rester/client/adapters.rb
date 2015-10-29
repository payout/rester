module Rester
  class Client
    module Adapters
      autoload(:Adapter,      'rester/client/adapters/adapter')
      autoload(:HttpAdapter,  'rester/client/adapters/http_adapter')
      autoload(:LocalAdapter, 'rester/client/adapters/local_adapter')
      autoload(:StubAdapter,  'rester/client/adapters/stub_adapter')

      class << self
        def list
          constants.map { |c| const_get(c) }
            .select { |c| c.is_a?(Class) && c < Adapter }
        end
      end
    end
  end
end
