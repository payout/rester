module Rester
  module Utils
    class LoggerWrapper
      attr_reader :logger

      def initialize(logger = Logger.new(STDOUT))
        @logger = logger
      end

      (Logger::SEV_LABEL - ['ANY']).map(&:downcase).map(&:to_sym).each do |sev|
        define_method(sev) { |msg| _log(sev, msg) if logger }
      end

      private

      def method_missing(meth, *args, &block)
        logger.public_send(meth, *args, &block)
      end

      def respond_to_missing?(*args)
        logger.respond_to?(*args)
      end

      def _log(level, msg)
        if Rester.processing_request?
          producer_name = Rester.request_info[:producer_name]
          consumer_name = Rester.request_info[:consumer_name]
          path = Rester.request_info[:path]
          verb = Rester.request_info[:verb]
          verb = verb && verb.upcase

          msg = "Correlation-ID=#{Rester.correlation_id} Consumer=" \
            "#{consumer_name} Producer=#{producer_name} #{verb} " \
            "#{path} - #{msg}"
        end

        logger.public_send(level, msg)
      end
    end # LoggerWrapper
  end # Utils
end # Rester