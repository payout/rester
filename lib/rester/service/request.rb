require 'rack'

module Rester
  class Service
    class Request < Rack::Request
      attr_reader :version
      attr_reader :object_chain

      CUSTOM_FIELDS = ['correlation_id', 'producer_name',
        'consumer_name'].freeze

      def initialize(env)
        super
        _parse_path if valid?
      end

      def valid?
        path.length < 256 && !!%r{\A/v\d+(/\w+/[\w-]+)*(/\w+)?/?\z}.match(path)
      end

      def each_resource
        return unless (chain = object_chain)

        loop do
          name, id, *chain = chain
          yield name, id
          break if chain.empty?
        end
      end

      CUSTOM_FIELDS.each { |field|
        define_method(field) { env["HTTP_X_RESTER_#{field.upcase}"] }
      }

      private

      def _parse_path
        _, version, *pieces = path.split(/\/+/)
        @version = version.downcase.to_sym
        @object_chain = pieces.map(&:freeze)
      end
    end # Request
  end # Service
end # Rester
