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
          'HTTP_X_RESTER_CORRELATION_ID' => id,
          'HTTP_X_RESTER_CONSUMER_NAME' => 'TestClient'
        }
      end

      describe '#call' do
        let(:logger) { double('logger') }

        before {
          allow(logger).to receive(:info)
          instance.logger = logger
        }

        subject { RequestHandler.new(instance).call(env) }
        after { subject }

        context 'with successful response' do
          before { allow(instance).to receive(:call) { [200, {}, []] } }

          it 'should set the producer name in the response' do
            expect(subject[1]['X-Rester-Producer-Name']).to eq 'Service'
          end

          it 'should clean up the Rester request' do
            subject
            expect(Rester.request_info).to eq nil
          end

          it 'should log the request and response' do
            expect(logger).to receive(:info).with("Correlation-ID=#{id} " \
              "Consumer=TestClient Producer=Service GET / - request received")
              .once
            expect(logger).to receive(:info).with(a_string_matching %r{
              \ACorrelation-ID=#{id}\sConsumer=TestClient\sProducer=Service\sGET\s
              /\s-\sresponding\swith\s200\safter\s0\.\d{3}ms\z}x).once
          end
        end # with successful response

        context 'with error response' do
          before { allow(instance).to receive(:call) { [500, {}, []] } }

          it 'should set the producer name in the response' do
            expect(subject[1]['X-Rester-Producer-Name']).to eq 'Service'
          end

          it 'should clean up the Rester request' do
            subject
            expect(Rester.request_info).to eq nil
          end

          it 'should log the request and response' do
            expect(logger).to receive(:info).with("Correlation-ID=#{id} " \
              "Consumer=TestClient Producer=Service GET / - request received")
              .once
            expect(logger).to receive(:info).with(a_string_matching %r{
              \ACorrelation-ID=#{id}\sConsumer=TestClient\sProducer=Service\sGET\s
              /\s-\sresponding\swith\s500\safter\s0\.\d{3}ms\z}x).once
          end
        end # with error response
      end # #call
    end # RequestHandler
  end # Service::Middleware
end # Rester
