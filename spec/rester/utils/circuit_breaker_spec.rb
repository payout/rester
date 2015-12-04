module Rester
  module Utils
    RSpec.describe CircuitBreaker do
      let(:block) { proc {} }
      let(:breaker) { CircuitBreaker.new(breaker_opts, &block) }

      let(:breaker_opts) do
        { threshold: threshold, retry_period: retry_period }
      end

      let(:threshold) { 5 }
      let(:retry_period) { 1 }

      def setup_for_failure
        allow(block).to receive(:call).and_raise 'hi'
      end

      def setup_for_success
        allow(block).to receive(:call).and_return 'hi'
      end

      def failure_call
        setup_for_failure
        expect { breaker.call }.to raise_error
      end

      def success_call
        setup_for_success
        expect(breaker.call).to eq 'hi'
      end

      def let_retry_period_pass
        sleep(retry_period * 2)
      end

      describe '#new' do
        subject { breaker }

        context 'with negative threshold' do
          let(:threshold) { -10 }

          it 'should raise ArgumentError' do
            expect { subject }.to raise_error ArgumentError,
              'threshold must be > 0'
          end
        end # with negative threshold

        context 'with zero threshold' do
          let(:threshold) { 0 }

          it 'should raise ArgumentError' do
            expect { subject }.to raise_error ArgumentError,
              'threshold must be > 0'
          end
        end # with zero theshold

        context 'with threshold = 0.001' do
          let(:threshold) { 0.001 }

          it 'should raise ArgumentError' do
            expect { subject }.to raise_error ArgumentError,
              'threshold must be > 0'
          end
        end # with theshold = 0.001

        context 'with negative retry_period' do
          let(:retry_period) { -10 }

          it 'should raise ArgumentError' do
            expect { subject }.to raise_error ArgumentError,
              'retry_period must be > 0'
          end
        end # with negative threshold

        context 'with zero retry_period' do
          let(:retry_period) { 0 }

          it 'should raise ArgumentError' do
            expect { subject }.to raise_error ArgumentError,
              'retry_period must be > 0'
          end
        end # with zero retry_period

        context 'with retry_period = 0.001' do
          let(:retry_period) { 0.001 }

          it 'should raise ArgumentError' do
            expect { subject }.not_to raise_error
          end
        end # with retry_period = 0.001
      end # #new

      describe '#threshold' do
        subject { breaker.threshold }

        context 'with no threshold option passed' do
          let(:breaker_opts) { {} }
          it { is_expected.to eq 3 }
        end

        context 'with threshold option passed as nil' do
          let(:threshold) { nil }
          it { is_expected.to eq 3 }
        end

        context 'with threshold option passed as 10' do
          let(:threshold) { 10 }
          it { is_expected.to eq 10 }
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

        context 'with failed calls followed by 1 successful call' do
          let(:threshold) { 5 }
          before { 4.times { failure_call }; success_call }
          it { is_expected.to eq 0 }
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

      describe '#closed?' do
        subject { breaker.closed? }

        context 'when never called' do
          it { is_expected.to be true }
        end

        context 'when successfully called' do
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

        context 'with threshold reached and retry period passed' do
          let(:retry_period) { 0.001 }
          before { threshold.times { failure_call }; let_retry_period_pass }
          it { is_expected.to be false }
        end
      end # #closed?

      describe '#half_open?' do
        subject { breaker.half_open? }

        context 'when never called' do
          it { is_expected.to be false }
        end

        context 'when called but closed' do
          before { success_call; expect(breaker.closed?).to be true }
          it { is_expected.to be false }
        end

        context 'when threshold reached' do
          let(:retry_period) { 5 }
          before { threshold.times { failure_call } }
          it { is_expected.to be false }
        end

        context 'when threshold reached and retry period passed' do
          let(:retry_period) { 0.001 }
          before { threshold.times { failure_call }; let_retry_period_pass }
          it { is_expected.to be true }
        end
      end # half_open?

      describe '#open?' do
        subject { breaker.open? }

        context 'when never called' do
          it { is_expected.to be false }
        end

        context 'when successfully called' do
          before { success_call }
          it { is_expected.to be false }
        end

        context 'when successfully called threshold times' do
          before { threshold.times { success_call } }
          it { is_expected.to be false }
        end

        context 'when threshold reached' do
          before { threshold.times { failure_call } }
          it { is_expected.to be true }
        end

        context 'when threshold reached but retry period passed' do
          let(:retry_period) { 0.001 }
          before { threshold.times { failure_call }; let_retry_period_pass }
          it { is_expected.to be false }
        end
      end # #open?

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
          before { failure_call; let_retry_period_pass }
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
      end # #reset

      describe '#on_open', :on_open do
        let(:callback) { proc {} }
        subject { breaker.on_open(&callback) }
        before { subject }

        it 'should return callback' do
          is_expected.to be callback
        end

        context 'with only successful calls' do
          after { threshold.times { success_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'without reaching threshold' do
          after { (threshold - 1).times { failure_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'with threshold reached' do
          after { threshold.times { failure_call } }

          it 'should call callback once' do
            expect(callback).to receive(:call).once
          end
        end

        context 'with threshold surpassed' do
          after { (threshold * 3).times { failure_call } }

          it 'should call callback once' do
            expect(callback).to receive(:call).once
          end
        end

        context 'with circuit opened and closed 5 times' do
          let(:retry_period) { 0.001 }
          after do
            5.times {
              threshold.times { failure_call }
              let_retry_period_pass
              success_call
            }
          end

          it 'should call callback 5 times' do
            expect(callback).to receive(:call).exactly(5).times
          end
        end # with circuit opened and closed 5 times
      end # #on_open

      describe '#on_close', :on_close do
        let(:callback) { proc {} }
        subject { breaker.on_close(&callback) }
        before { subject }

        it 'should return callback' do
          is_expected.to be callback
        end

        context 'with only successful calls' do
          after { threshold.times { success_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'without reaching threshold' do
          after { (threshold - 1).times { failure_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'with threshold reached' do
          after { threshold.times { failure_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'with threshold surpassed' do
          after { (threshold * 3).times { failure_call } }

          it 'should not call callback' do
            expect(callback).not_to receive :call
          end
        end

        context 'with successful call after threshold reached' do
          let(:retry_period) { 0.001 }
          after do
            threshold.times { failure_call }
            let_retry_period_pass
            success_call
          end

          it 'should call callback once' do
            expect(callback).to receive(:call).once
          end
        end # with successful call after threshold reached

        context 'with many successful calls after threshold reached' do
          let(:retry_period) { 0.001 }
          after do
            threshold.times { failure_call }
            let_retry_period_pass
            (threshold * 3).times { success_call }
          end

          it 'should call callback once' do
            expect(callback).to receive(:call).once
          end
        end # with many successful call after threshold reached

        context 'with circuit opened and closed 5 times' do
          let(:retry_period) { 0.001 }
          after do
            5.times {
              threshold.times { failure_call }
              let_retry_period_pass
              success_call
            }
          end

          it 'should call callback 5 times' do
            expect(callback).to receive(:call).exactly(5).times
          end
        end # with circuit opened and closed 5 times
      end # #on_close

      describe '#call' do
        let(:args) { [] }
        subject { breaker.call(*args) }

        context 'with successful call' do
          before { setup_for_success }

          it 'should return retval of block' do
            is_expected.to eq 'hi'
          end

          it 'should call block once' do
            expect(block).to receive(:call).once
            subject
          end
        end

        context 'with args passed' do
          let(:args) { [1, :two, 'three', 4.0] }
          after { subject }

          it 'should pass args to block' do
            expect(block).to receive(:call).with(*args).once
          end
        end

        context 'with failed call' do
          before { setup_for_failure }

          it 'should raise exception raised by block' do
            expect { subject }.to raise_error RuntimeError, 'hi'
          end

          it 'should call block once' do
            expect(block).to receive(:call).once
            expect { subject }.to raise_error
          end
        end

        context 'with 5 successful calls after recovering' do
          let(:retry_period) { 0.001 }
          before { threshold.times { failure_call }; let_retry_period_pass }
          after { 5.times { success_call } }

          it 'should call block 5 times' do
            expect(block).to receive(:call).exactly(5).times
          end
        end

        context 'with failure after recovering' do
          let(:retry_period) { 0.001 }

          before do
            threshold.times { failure_call }
            let_retry_period_pass
            success_call # Recover

            # Need to set it up for failure, since `success_call` will have
            # set it up for success.
            setup_for_failure
          end

          it 'should raise exception raised by block' do
            expect { subject }.to raise_error RuntimeError, 'hi'
          end

          it 'should call block once' do
            expect(block).to receive(:call).once
            expect { subject }.to raise_error
          end
        end # with failure after recovering

        context 'with 5 failure calls after recovering' do
          let(:retry_period) { 0.001 }

          before do
            threshold.times { failure_call }
            let_retry_period_pass
            success_call # Recover
          end

          after { 5.times { failure_call } }

          it 'should call block 5 times' do
            expect(block).to receive(:call).exactly(5).times
          end
        end

        context 'with 5 failure calls after failing to recover' do
          let(:retry_period) { 0.001 }

          before do
            threshold.times { failure_call }
            let_retry_period_pass
            failure_call # Fail to recover
          end

          after { 5.times { failure_call } }

          it 'should call block 0 times' do
            expect(block).not_to receive(:call)
          end
        end

        context 'with threshold reached' do
          before { threshold.times { failure_call } }

          it 'should raise CircuitOpenError' do
            expect { subject }.to raise_error CircuitBreaker::CircuitOpenError
          end

          it 'should not continue to call block' do
            expect(block).not_to receive(:call)
            expect { subject }.to raise_error
          end
        end

        context 'with retry period passed followed by failure' do
          let(:retry_period) { 0.001 }
          before { threshold.times { failure_call }; let_retry_period_pass }

          it 'should raise exception raised by block' do
            expect { subject }.to raise_error RuntimeError, 'hi'
          end

          it 'should call block once' do
            expect(block).to receive(:call).once
            expect { subject }.to raise_error
          end
        end

        context 'with retry period passed followed by success' do
          let(:retry_period) { 0.001 }

          before do
            threshold.times { failure_call }
            let_retry_period_pass

            # Need to set it up for success, since `failure_call` will have
            # set it up for failure.
            setup_for_success
          end

          it 'should return retval of block' do
            is_expected.to eq 'hi'
          end

          it 'should call block once' do
            expect(block).to receive(:call).once
            subject
          end
        end # with retry period passed followed by success
      end # #call
    end # CircuitBreaker
  end # Utils
end # Rester
