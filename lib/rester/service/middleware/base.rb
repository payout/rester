module Rester
  module Service::Middleware
    class Base
      attr_reader :app
      attr_reader :options

      def initialize(app, options = {})
        @app = app
        @options = options
      end

      def call(env)
        app.call(env)
      end

      def service
        @__service ||= _find_service
      end

      private

      def _find_service
        service = app

        loop {
          break if service.is_a?(Service)

          [:app, :target].each { |meth|
            if service.respond_to?(meth)
              service = service.public_send(meth)
              break
            end
          }
        }

        service.is_a?(Service) && service
      end

      def _error!(klass, message=nil)
        Errors.throw_error!(klass, message)
      end
    end # Base
  end # Service::Middleware
end # Rester
