module Rester
  module Service::Middleware
    RSpec.describe ErrorHandling do
      let(:service) {
        Class.new(Service).tap { |klass|
          allow(klass).to receive(:name) { 'Service' }
        }
      }
      let(:instance) { service.new }
      let(:env) { {} }
      let(:id) { SecureRandom.uuid }
      let(:producer_name) { 'TestProducer' }
      let(:consumer_name) { 'TestConsumer' }

      around do |ex|
        Rester.wrap_request do
          Rester.correlation_id = id
          Rester.request_info[:producer_name] = producer_name
          Rester.request_info[:consumer_name] = consumer_name
          Rester.request_info[:verb] = 'GET'
          Rester.request_info[:path] = '/v1/tests'
          ex.run
        end
      end

      describe '#call' do
        let(:logger) { double('logger') }

        subject { ErrorHandling.new(instance).call(env) }

        before {
          allow(logger).to receive(:error)
          instance.logger = logger
        }

        context 'with server error' do
          before { allow(instance).to receive(:call) { fail 'error' } }

          it 'should log the error' do
            expect(logger).to receive(:error).with("Correlation-ID=#{id} " \
              "Consumer=#{consumer_name} Producer=#{producer_name} GET " \
              "/v1/tests - #<RuntimeError: error>")
            subject
          end

          it 'should respond with 500' do
            expect(subject[0]).to eq 500
          end
        end # with server error

        context 'with validation error' do
          before {
            allow(instance).to receive(:call) {
              Errors.throw_error!(Errors::ValidationError, 'error')
            }
          }

          it 'should log the error' do
            expect(logger).to receive(:error).with("Correlation-ID=#{id} " \
              "Consumer=#{consumer_name} Producer=#{producer_name} GET " \
              "/v1/tests - #<Rester::Errors::ValidationError: error>")
            subject
          end

          it 'should respond with 400' do
            expect(subject[0]).to eq 400
          end
        end # with validation error
      end # #call
    end # ErrorHandling
  end # Service::Middleware
end # Rester
