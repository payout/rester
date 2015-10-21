require 'rester'

module Rester
  class DummyService < Service
    module V1
      class MountedObject < Service::Resource
        def search(params)
          params.merge(method: :search)
        end

        def get(params)
          params
        end

        def update(params)
          params
        end

        def delete
          { no: 'params accepted' }
        end

        mount MountedObject
      end # MountedObject

      class Test < Service::Resource
        id :token
        mount MountedObject

        params do
          String  :string
          Integer :integer
          Float   :float
          Symbol  :symbol
          Boolean :bool
        end

        def search(params)
          params.merge(method: :search)
        end

        def create(params)
          params.merge(method: :create)
        end

        def get(params)
          { token: params.delete(:test_token), params: params, method: :get }
        end

        def update(params)
          {
            method: :update,
            int: 1, float: 1.1, bool: true, null: nil,
            params: params
          }
        end

        def delete(params)
          _a_private_method(params).merge(method: :delete)
        end

        private

        def _a_private_method(params)
          get(params)
        end
      end # Test

      class TestWithDefaults < Service::Resource
        params do
          String  :string_with_default,  default: "default"
          Integer :integer_with_default, default: 1
          Float   :float_with_default,   default: 3.14
          Symbol  :symbol_with_default,  default: :default
          Boolean :bool_with_default,    default: true
        end

        def search(params)
          params.merge(method: :search)
        end

        def get(params)
          { token: params.delete(:test_token), params: params, method: :get }
        end
      end # TestWithDefaults
    end # V1
  end # DummyService
end # Rester
