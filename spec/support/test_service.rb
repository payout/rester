# Intended to be used by the service_spec

require 'rester'

class TestService < Rester::Service
  module V1
    class MountedResource < Rester::Service::Resource
      [:search, :create, :get, :delete, :update].each do |meth|
        define_method(meth) { |params|
          { resource: :mounted, method: meth, params: params }
        }
      end
    end

    class Test < Rester::Service::Resource
      mount MountedResource

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
