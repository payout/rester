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
        @_mutex = Mutex.new
        @threshold = (opts[:threshold] || 5).to_i
        @retry_period = (opts[:retry_period] || 1).to_f
        @block = block
        reset
      end

      ##
      # Signifies that is "live".
      def closed?
        !reached_threshold? || retry_period_passed?
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
          begin
            block.call(*args).tap { record_success }
          rescue
            _record_failure
            raise
          end
        else
          raise CircuitOpenError
        end
      end

      def reset
        _synchronize {
          @failure_count = 0
          @last_failed_at = nil
        }
      end

      private

      def _synchronize(&block)
        @_mutex.synchronize(&block)
      end

      ##
      # For each attempt we decrease the failure count if necessary.
      # This allows for a gradual recovery.
      def record_success
        if @failure_count > 0
          _synchronize { @failure_count -= 1 if @failure_count > 0 }
        end
      end

      def _record_failure
        _synchronize {
          @failure_count += 1 if @failure_count < threshold
          @last_failed_at = Time.now
        }
      end
    end # CircuitBreaker
  end # Utils
end # Rester
