require 'rester'
require 'dummy/dummy_service'

module RSpec
  class << self
    def start_server
      service = Rester::DummyService

      Thread.new {
        Rack::Handler::WEBrick.run(service, :Port => 9292)
      }

      @_rbn_server_uri = URI('http://localhost:9292')

      # Wait for server to be ready.
      sleep(1)
    end

    def server_uri
      @_rbn_server_uri
    end
  end
end
