module Rester
  module Utils
    class CircuitBreaker
      class Error < StandardError; end
      class CircuitOpenError < Error; end

      attr_reader :threshold
      attr_reader :retry_period
      attr_reader :block

      attr_reader :failure_count
      attr_reader :last_failed_at

      def initialize(opts={}, &block)
        @_synchronizer = Mutex.new
        @_retry_lock = Mutex.new
        self.threshold = opts[:threshold]
        self.retry_period = opts[:retry_period]
        @block = block
        reset
      end

      def on_open(&block)
        _callbacks[:open] = block
      end

      def on_close(&block)
        _callbacks[:close] = block
      end

      def closed?
        !reached_threshold?
      end

      def half_open?
        !closed? && retry_period_passed?
      end

      def open?
        !closed? && !half_open?
      end

      def reached_threshold?
        failure_count >= threshold
      end

      def retry_period_passed?
        lf_at = last_failed_at
        !lf_at || (Time.now - lf_at) > retry_period
      end

      def call(*args)
        if closed?
          _call(*args)
        elsif half_open? && @_retry_lock.try_lock
          # Ensure only one thread can retry.
          begin
            _call(*args)
          ensure
            @_retry_lock.unlock
          end
        else
          fail CircuitOpenError
        end
      end

      def reset
        _synchronize do
          @failure_count = 0
          @last_failed_at = nil
        end
      end

      protected

      def threshold=(threshold)
        unless (@threshold = (threshold || 3).to_i) > 0
          fail ArgumentError, 'threshold must be > 0'
        end
      end

      def retry_period=(retry_period)
        unless (@retry_period = (retry_period || 1).to_f) > 0
          fail ArgumentError, 'retry_period must be > 0'
        end
      end

      private

      def _call(*args)
        begin
          block.call(*args).tap { _record_success }
        rescue
          _record_failure
          raise
        end
      end

      def _callbacks
        @__callbacks ||= {}
      end

      def _call_on(type)
        (cb = _callbacks[type]) && cb.call
      end

      def _synchronize(&block)
        @_synchronizer.synchronize(&block)
      end

      def _record_success
        if @failure_count > 0
          _synchronize do
            # If the threshold had been reached, we're now closing the circuit.
            _call_on(:close) if @failure_count == threshold
            @failure_count = 0
          end
        end
      end

      def _record_failure
        if @failure_count < threshold
          _synchronize do
            if @failure_count < threshold
              @failure_count += 1

              # If the threshold has now been reached, we're opening the circuit.
              _call_on(:open) if @failure_count == threshold
            end
          end
        end

        @last_failed_at = Time.now
      end
    end # CircuitBreaker
  end # Utils
end # Rester
