require 'rester'

class ResterService < Rester::Service
  module V1
    class ResterResource < Rester::Service::Resource
    end
  end
end