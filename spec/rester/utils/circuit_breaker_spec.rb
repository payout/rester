module Rester
  module Utils
    RSpec.describe CircuitBreaker do
      let(:breaker) { CircuitBreaker.new(breaker_opts) {} }

      let(:breaker_opts) do
        { threshold: threshold, retry_period: retry_period }
      end

      let(:threshold) { 5 }
      let(:retry_period) { 1 }

      let(:error_message) { 'hi' }

      def failure_call
        allow(breaker.block).to receive(:call).and_raise error_message
        expect { breaker.call }.to raise_error error_message
      end

      def success_call
        allow(breaker.block).to receive(:call).and_return 'hi'
        expect(breaker.call).to eq 'hi'
      end

      describe '#threshold' do
        subject { breaker.threshold }

        context 'with no threshold option passed' do
          let(:breaker_opts) { {} }
          it { is_expected.to eq 5 }
        end

        context 'with threshold option passed as nil' do
          let(:threshold) { nil }
          it { is_expected.to eq 5 }
        end

        context 'with threshold option passed as 10' do
          let(:threshold) { 10 }
          it { is_expected.to eq 10 }
        end

        context 'with threshold option passed as 0.001' do
          let(:threshold) { 0.001 }
          it { is_expected.to eq 0 }
        end
      end # #threshold

      describe '#retry_period' do
        subject { breaker.retry_period }

        context 'with no retry_period option passed' do
          let(:breaker_opts) { {} }
          it { is_expected.to eq 1 }
        end

        context 'with retry_period option passed as nil' do
          let(:retry_period) { nil }
          it { is_expected.to eq 1 }
        end

        context 'with retry_period option passed as 10' do
          let(:retry_period) { 10 }
          it { is_expected.to eq 10 }
        end

        context 'with retry_period option passed as 0.001' do
          let(:retry_period) { 0.001 }
          it { is_expected.to eq 0.001 }
        end
      end # #retry_period

      describe '#failure_count' do
        subject { breaker.failure_count }

        context 'with no calls' do
          it { is_expected.to eq 0 }
        end

        context 'with a successful call' do
          before { success_call }
          it { is_expected.to eq 0 }
        end

        context 'with 100 successful calls' do
          before { (100).times { success_call } }
          it { is_expected.to eq 0 }
        end

        context 'with one failed call' do
          before { failure_call }
          it { is_expected.to eq 1 }
        end

        context 'with 5 failed calls and threshold = 5' do
          let(:threshold) { 5 }
          before { threshold.times { failure_call } }
          it { is_expected.to eq threshold }
        end

        context 'with 6 failed calls and threshold = 5' do
          let(:threshold) { 5 }
          before { 6.times { failure_call } }
          it { is_expected.to eq 5 }
        end

        context 'with 4 failed calls, 2 successful calls and threshold = 5' do
          let(:threshold) { 5 }
          before { 4.times { failure_call }; 2.times { success_call } }
          it { is_expected.to eq 2 }
        end
      end # #failure_count

      describe '#last_failed_at' do
        subject { breaker.last_failed_at }

        context 'with no failures' do
          it { is_expected.to be nil }
        end

        context 'with failure' do
          before { failure_call }
          it { is_expected.to be_within(1.second).of(Time.now) }
        end
      end # #last_failed_at

      describe '#last_exception' do
        subject { breaker.last_exception }

        context 'with no failures' do
          it { is_expected.to be nil }
        end

        context 'with failure' do
          before { failure_call }
          it { is_expected.to be_a RuntimeError }
          it { is_expected.to have_attributes(message: 'hi') }
        end
      end # #last_exception

      describe '#closed?' do
        subject { breaker.closed? }

        context 'never called' do
          it { is_expected.to be true }
        end

        context 'successfully called' do
          before { threshold.times { success_call } }
          it { is_expected.to be true }
        end

        context 'with one failure' do
          before { failure_call }
          it { is_expected.to be true }
        end

        context 'with threshold reached' do
          before { threshold.times { failure_call } }
          it { is_expected.to be false }
        end
      end # #closed?

      describe '#reached_threshold?' do
        subject { breaker.reached_threshold? }

        context 'with no calls' do
          it { is_expected.to be false }
        end # with no calls

        context 'with the threshold not met' do
          before { (threshold - 1).times { failure_call } }
          it { is_expected.to be false }
        end # with the threshold not met

        context 'after reaching threshold' do
          before { threshold.times { failure_call } }
          it { is_expected.to be true }
        end # after reaching threshold

        context 'after "surpassing" threshold' do
          before { (threshold + 1).times { failure_call } }
          it { is_expected.to be true }
        end # after "surpassing" threshold
      end # #reached_threshold?

      describe '#retry_period_passed?' do
        subject { breaker.retry_period_passed? }

        context 'with no failures' do
          it { is_expected.to be true }
        end

        context 'with a failure within retry period' do
          before { failure_call }
          it { is_expected.to be false }
        end

        context 'with a failure past retry period' do
          let(:retry_period) { 0.001 }
          before { failure_call; sleep(retry_period * 2) }
          it { is_expected.to be true }
        end
      end # #retry_period_passed?

      describe '#reset' do
        subject { breaker.reset }
        before { failure_call; subject }

        it { is_expected.to be nil }

        it 'should set failure_count = 0' do
          expect(breaker.failure_count).to eq 0
        end

        it 'should set last_failed_at = nil' do
          expect(breaker.last_failed_at).to be nil
        end

        it 'should set last_exception = nil' do
          expect(breaker.last_exception).to be nil
        end
      end # #reset

      describe '#call' do
        subject { breaker.call }

        context 'with successful call' do
          before { allow(breaker.block).to receive(:call).and_return 'hi' }

          it 'should return retval of block' do
            is_expected.to eq 'hi'
          end
        end

        context 'with failed call' do
          before do
            allow(breaker.block).to receive(:call).and_raise "#{error_message}2"
          end

          it 'should raise exception raised by block' do
            expect { subject }.to raise_error RuntimeError, "#{error_message}2"
          end

          context 'with threshold reached' do
            before { threshold.times { failure_call } }

            it 'should raise last exception' do
              # Note here it's raising the exception raised in `failure_call`
              # and not the exception that would be raised if it actually called
              # the block.
              expect { subject }.to raise_error RuntimeError, error_message
            end
          end
        end
      end # #call
    end # CircuitBreaker
  end # Utils
end # Rester
