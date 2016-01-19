module Rester
  module Service::Middleware
    ##
    # Provides a basic status check. Used by the Client#connected? method.
    class Ping < Base
      def call(env)
        if %r{\A/ping\z}.match(Rester.request.path_info)
          [200, {}, []]
        else
          super
        end
      end
    end # Ping
  end # Service::Middleware
end # Rester
