require 'new_relic/agent'
require 'active_support/inflector'

NewRelic::Agent.manual_start unless defined?(Rails)

module Rester
  module Service::Middleware
    class NewRelic < Base
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def call(env)
        request = Service::Request.new(env)
        name = identify_method(request)
        ::NewRelic::Agent.set_transaction_name(name, category: :controller)
        super
      end

      def identify_method(request)
        object_chain = request.object_chain

        if object_chain.length.odd?
          resource_name = object_chain.last
        else
          resource_name = object_chain[-2]
        end

        method = _determine_method(request)

        "#{service.class.name}::#{request.version.to_s.upcase}::"\
          "#{resource_name.singularize.camelcase}/#{method}"
      end

      private

      def _determine_method(request)
        if request.object_chain.length.odd?
          case request.request_method
          when 'GET'  then 'search'
          when 'POST' then 'create'
          end
        else
          case request.request_method
          when 'GET'    then 'get'
          when 'PUT'    then 'update'
          when 'DELETE' then 'delete'
          end
        end
      end
    end
  end
end
