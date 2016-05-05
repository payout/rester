module Rester
  class Client
    module Adapters
      autoload(:Adapter,      'rester/client/adapters/adapter')
      autoload(:HttpAdapter,  'rester/client/adapters/http_adapter')
      autoload(:LocalAdapter, 'rester/client/adapters/local_adapter')
      autoload(:StubAdapter,  'rester/client/adapters/stub_adapter')

      ##
      # Default connection options.
      DEFAULT_OPTS = {
        timeout: 10 # time in seconds (may be float)
      }.freeze

      class << self
        ##
        # Returns a list of available adapter classes.
        def list
          constants.map { |c| const_get(c) }
            .select { |c| c.is_a?(Class) && c < Adapter }
        end

        ##
        # Returns an instance of the appropriate adapter that is connected to
        # the service.
        def connect(service, opts={})
          klass = list.find { |a| a.can_connect_to?(service) }
          fail "unable to find an adapter for #{service.inspect}" unless klass
          klass.new(service, opts)
        end

        ##
        # Given a hash, extracts the options that are part of the adapter
        # interface.
        def extract_opts(opts={})
          sel = proc { |k, _| DEFAULT_OPTS.keys.include?(k) }
          DEFAULT_OPTS.merge(opts.select(&sel).tap { opts.delete_if(&sel) })
        end
      end
    end
  end
end
