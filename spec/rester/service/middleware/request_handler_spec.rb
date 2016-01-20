require 'support/test_service'

module Rester
  module Service::Middleware
    RSpec.describe RequestHandler do
      let(:service) {
        Class.new(Service).tap { |klass|
          allow(klass).to receive(:name) { 'Service' }
        }
      }
      let(:instance) { service.new }
      let(:id) { SecureRandom.uuid }
      let(:env) do
        {
          'REQUEST_METHOD' => 'GET',
          'PATH_INFO'      => '/',
          'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
          'QUERY_STRING'   => '',
          'rack.input'     => StringIO.new(''),
          'HTTP_X_RESTER_CORRELATION_ID' => id,
          'HTTP_X_RESTER_CONSUMER_NAME' => 'TestClient'
        }
      end
      before { allow(instance).to receive(:call) { [200, {}, []] } }
      subject { RequestHandler.new(instance).call(env) }

      it 'should set the producer name in the response' do
        expect(subject[1]['X-Rester-Producer-Name']).to eq 'Service'
      end

      it 'should clean up the Rester request' do
        subject
        expect(Rester.request_info).to eq nil
      end

      describe 'logging' do
        let(:logger) { double('logger') }
        before { Rester.logger = logger }
        after {
          subject
          Rester.logger = Logger.new(STDOUT) # reset the logger
        }

        it 'should log the request and response' do
          expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
            "TestClient -> [Service] - GET /").once
          expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
            "TestClient <- [Service] - GET / 200").once
        end

        context 'with error' do
          it 'should log the request and response' do
            expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
              "TestClient -> [Service] - GET /").once
            expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
              "TestClient <- [Service] - GET / 200").once
          end
        end # with error
      end # logging
    end # RequestHandler
  end # Service::Middleware
end # Rester