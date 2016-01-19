require 'rester'

class NewRelicTestService < Rester::Service
  use Rester::Service::Middleware::NewRelic

  module V1
    class MountedResource < Rester::Service::Resource
      id :token

      def search
      end
    end

    class Test < Rester::Service::Resource
      mount MountedResource

      def search
      end

      def create
      end
    end
  end
end
