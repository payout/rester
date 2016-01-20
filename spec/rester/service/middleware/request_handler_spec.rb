require 'support/test_service'

module Rester
  module Service::Middleware
    RSpec.describe RequestHandler do
      let(:service) {
        Class.new(TestService).tap { |klass|
          allow(klass).to receive(:name) { 'TestService' }
        }
      }
      let(:id) { SecureRandom.uuid }
      let(:env) do
        {
          'REQUEST_METHOD' => 'GET',
          'PATH_INFO'      => '/v1/tests',
          'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
          'QUERY_STRING'   => '',
          'rack.input'     => StringIO.new(''),
          'HTTP_X_RESTER_CORRELATION_ID' => id,
          'HTTP_X_RESTER_CONSUMER_NAME' => 'TestClient'
        }
      end

      subject { service.call(env) }

      it 'should set the producer name in the response' do
        expect(subject[1]['HTTP_X_RESTER_PRODUCER_NAME']).to eq 'TestService'
      end

      it 'should clean up the Rester request' do
        subject
        expect(Rester.request_info).to eq nil
      end

      describe 'logging' do
        let(:logger) { double('logger') }
        before { service.logger = logger }

        after { subject }

        it 'should log the request and response' do
          expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
            "TestClient -> [TestService] - GET /v1/tests").once
          expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
            "TestClient <- [TestService] - GET /v1/tests 200").once
        end

        context 'with validation error' do
          before {
            allow(service.instance).to receive(:call) {
              Errors.throw_error!(Errors::ValidationError)
            }
          }

          it 'should log the request and response' do
            expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
              "TestClient -> [TestService] - GET /v1/tests").once
            expect(logger).to receive(:info).with("Correlation-ID=#{id}: " \
              "TestClient <- [TestService] - GET /v1/tests 400").once
          end
        end # with validation error
      end # logging
    end # RequestHandler
  end # Service::Middleware
end # Rester