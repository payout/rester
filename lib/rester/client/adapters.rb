module Rester
  class Client
    module Adapters
      autoload(:Adapter,      'rester/client/adapters/adapter')
      autoload(:HttpAdapter,  'rester/client/adapters/http_adapter')
      autoload(:LocalAdapter, 'rester/client/adapters/local_adapter')
      autoload(:StubAdapter,  'rester/client/adapters/stub_adapter')

      def self.list
        self.constants.reject { |const|
          const == :Adapter || !self.const_get(const).is_a?(Class)
        }.map { |c|
          self.const_get(c)
        }
      end
    end
  end
end
