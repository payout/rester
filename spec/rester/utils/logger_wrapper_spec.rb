module Rester
  module Utils
    RSpec.describe LoggerWrapper do
      describe '#initialize' do
        subject { LoggerWrapper.new(logger).logger }

        context 'with default logger' do
          let(:logger) { nil }
          it { is_expected.to be_a Logger }

          it 'should allow the standard logger methods' do
            (Logger::SEV_LABEL - ['ANY']).each { |sev|
              expect(subject.respond_to?(sev.downcase.to_sym)).to be true
            }
          end
        end # with default logger

        context 'with logger passed in' do
          let(:logger) { double('logger') }
          it { is_expected.to eq logger }
        end # with logger passed in
      end # #initialize

      describe '#info' do
        subject { logger.info(msg) }
        let(:logger) { LoggerWrapper.new(custom_logger) }
        let(:custom_logger) { double('logger') }
        let(:msg) { "some message" }

        it 'should log the message' do
          expect(custom_logger).to receive(:info).with(msg)
          subject
        end

        context 'within a request' do
          let(:id) { SecureRandom.uuid }

          before {
            Rester.begin_request
            Rester.correlation_id = id
            Rester.request_info[:producer_name] = 'producer'
            Rester.request_info[:consumer_name] = 'consumer'
            Rester.request_info[:path] = '/v1/tests'
            Rester.request_info[:verb] = 'GET'
          }
          after { Rester.end_request }

          it 'should log the message' do
            expect(custom_logger).to receive(:info).with("Correlation-ID=" \
              "#{id} Consumer=consumer Producer=producer GET /v1/tests - some" \
              " message")
            subject
          end
        end
      end # #info
    end # LoggerWrapper
  end # Utils
end # Rester