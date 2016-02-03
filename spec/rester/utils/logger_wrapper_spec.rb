module Rester
  module Utils
    RSpec.describe LoggerWrapper do
      describe '#new' do
        subject { LoggerWrapper.new(logger) }

        context 'with default logger' do
          subject { LoggerWrapper.new }

          it { expect(subject.logger).to be_a Logger }

          it 'should allow the standard logger methods' do
            (Logger::SEV_LABEL - ['ANY']).each { |sev|
              expect(subject.respond_to?(sev.downcase.to_sym)).to be true
            }
          end
        end # with default logger

        context 'with logger passed in' do
          let(:logger) { double('logger') }
          it { expect(subject.logger).to eq logger }
        end # with logger passed in

        context 'with logger disabled' do
          let(:logger) { nil }
          it { expect(subject.logger).to eq nil }
        end # with logger disabled
      end # #new

      describe '#info' do
        subject { logger.info(msg) }
        let(:logger) { LoggerWrapper.new(custom_logger) }
        let(:custom_logger) { double('logger') }
        let(:msg) { "some message" }

        it 'should log the message' do
          expect(custom_logger).to receive(:info).with(msg)
          subject
        end

        context 'with logging disabled' do
          let(:logger) { LoggerWrapper.new }

          it 'should not raise an error when logging' do
            expect { logger.info("message") }.not_to raise_error
          end
        end # with logging disabled

        context 'within a request' do
          let(:id) { SecureRandom.uuid }

          around do |ex|
            Rester.wrap_request do
              Rester.correlation_id = id
              Rester.request_info[:producer_name] = 'producer'
              Rester.request_info[:consumer_name] = 'consumer'
              Rester.request_info[:path] = '/v1/tests'
              Rester.request_info[:verb] = 'GET'
              ex.run
            end
          end

          it 'should log the message' do
            expect(custom_logger).to receive(:info).with("Correlation-ID=" \
              "#{id} Consumer=consumer Producer=producer GET /v1/tests - some" \
              " message")
            subject
          end
        end # within a request
      end # #info
    end # LoggerWrapper
  end # Utils
end # Rester
