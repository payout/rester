# Intended to be used by the service_spec

require 'rester'

class TestService < Rester::Service
  module V1
    class Test < Rester::Service::Resource
      [:search, :create, :get, :delete, :update].each do |meth|
        define_method(meth) { |params|
          { method: meth, params: params }
        }
      end
    end

    class Error < Rester::Service::Resource
      [:search, :create, :get, :delete, :update].each do |meth|
        define_method(meth) { |params|
          error!(meth, params.to_json)
        }
      end
    end

    class CustomIdName < Rester::Service::Resource
      id :custom

      [:get, :delete, :update].each do |meth|
        define_method(meth) { |params|
          { method: meth, params: params }
        }
      end
    end
  end
end
