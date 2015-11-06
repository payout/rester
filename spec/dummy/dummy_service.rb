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

        shared_params = Params.new {
          String  :string
          Integer :integer, between?: [0,100]
          Float   :float
          Symbol  :symbol
          Boolean :bool
        }

        params do
          use shared_params
          String :my_string
        end
        def search(params)
          params.merge(method: :search)
        end

        params do
          use shared_params
        end
        def create(params)
          params.merge(method: :create)
        end

        params do
          use shared_params
        end
        def get(params)
          error! if params[:string] == 'testing_error'
          error!(params[:string]) if params[:string] == 'testing_error_with_message'

          { token: params.delete(:test_token), params: params, method: :get }
        end

        params do
          use shared_params
        end
        def update(params)
          {
            method: :update,
            int: 1, float: 1.1, bool: true, null: nil,
            params: params
          }
        end

        params do
          use shared_params
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
        shared_params = Params.new {
          String  :string_with_default,  default: 'string'
          Integer :integer_with_default, default: 1
          Float   :float_with_default,   default: 3.14
          Symbol  :symbol_with_default,  default: :default
          Boolean :bool_with_default,    default: true
        }

        params do
          use shared_params
        end
        def search(params)
          params.merge(method: :search)
        end

        params do
          use shared_params
        end
        def get(params)
          { token: params.delete(:test_token), params: params, method: :get }
        end
      end # TestWithDefaults

      class TestWithNonHashValue < Service::Resource
        shared_params = Params.new {
          Boolean :nil_return_val, default: false
        }

        params do
          use shared_params
        end
        def search(params)
          params[:nil_return_val] ? nil : [[:this, :that]]
        end
      end # TestWithNonHashValue
    end # V1
  end # DummyService
end # Rester
