module Rester
  module Middleware
    ##
    # Provides a basic status check. Used by the Client#connected? method.
    class StatusCheck < Base
      def call(env)
        if %r{\A/v[\d+]/status\z}.match(env['REQUEST_PATH'])
          [200, {}, []]
        else
          super
        end
      end
    end # StatusCheck
  end # Middleware
end # Rester
