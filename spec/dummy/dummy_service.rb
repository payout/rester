require 'rester'

module Rester
  class DummyService < Service
    module V1
      class MountedObject < Service::Resource
        params strict: false do
        end
        def search(params)
          params.merge(method: :search)
        end

        params strict: false do
        end
        def get(params)
          params
        end

        params strict: false do
        end
        def update(params)
          params
        end

        params strict: false do
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

        params strict: false do
          use shared_params
          String :my_string
        end
        def search(params)
          params.merge(method: :search)
        end

        params strict: false do
          use shared_params
          Boolean :create_token
        end
        def create(params)
          params.merge!(token: 'ATrandomtoken') if params[:create_token]
          params.merge(method: :create)
        end

        params strict: false do
          use shared_params
        end
        def get(params)
          error!('testing_error') if params[:string] == 'testing_error'

          if params[:string] == 'testing_error_with_message'
            error!('testing_error', 'with_message')
          end

          { token: params.delete(:test_token), params: params, method: :get }
        end

        params strict: false do
          use shared_params
        end
        def update(params)
          {
            method: :update,
            int: 1, float: 1.1, bool: true, null: nil,
            params: params
          }
        end

        params strict: false do
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

      class TestWithParams < Service::Resource
        params do
          String :my_string, default: "string"
        end
        def search(params)
          params
        end

        params do
          Integer :my_integer, default: 1
        end
        def create(params)
          params
        end

        params do
          Symbol :my_symbol, default: :symbol
        end
        def get(params)
          params
        end

        params do
          Float :my_float, default: 1.23
        end
        def update(params)
          params
        end

        params do
          Boolean :my_boolean, default: true
        end
        def delete(params)
          params
        end
      end # TestWithParams
    end # V1
  end # DummyService
end # Rester
