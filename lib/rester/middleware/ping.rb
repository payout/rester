module Rester
  module Middleware
    ##
    # Provides a basic status check. Used by the Client#connected? method.
    class Ping < Base
      def call(env)
        if %r{\A/ping\z}.match(env['REQUEST_PATH'])
          [200, {}, []]
        else
          super
        end
      end
    end # Ping
  end # Middleware
end # Rester