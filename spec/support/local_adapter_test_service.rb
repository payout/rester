# Intended to be used by the local_adapter_spec

require 'rester'

class LocalAdapterTestService < Rester::Service
  module V1
    class Test < Rester::Service::Resource
      params do
        String :query
      end
      def search(params)
        if params[:query]
          message = "query provided: #{params[:query]}"
        else
          message = "no query provided"
        end

        { message: message }
      end

      params do
        String :d1
        Integer :d2
        Float :d3
      end
      def create(params)
        params
      end

      def get(params)
        params
      end

      params do
        String :test_id
        Array :a
        Hash :h do
          String :key
        end
      end
      def update(params)
        params
      end
    end
  end
end
