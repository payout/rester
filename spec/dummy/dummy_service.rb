require 'rester'

module Rester
  class DummyService < Service
    module V1
      class MountedObject < Service::Object
        class << self
          def search(params)
            params.merge(method: :search)
          end

          def create(params)
            params.merge(method: :create)
          end
        end # Class Methods

        def get(params)
          params.merge(id: id)
        end

        def update(params)
          params
        end

        mount MountedObject
      end # MountedObject

      class Test < Service::Object
        id :token
        mount MountedObject

        class << self
          def search(params)
            params.merge(method: :search)
          end

          def create(params)
            params.merge(method: :create)
          end
        end # Class Methods

        def get(params)
          { token: token, params: params, method: :get }
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
    end # V1
  end # DummyService
end # Rester
