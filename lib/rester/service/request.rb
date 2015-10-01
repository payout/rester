require 'rack'

module Rester
  class Service
    class Request < Rack::Request
      attr_reader :version
      attr_reader :object_chain

      def initialize(env)
        super
        _parse_path if valid?
      end

      def valid?
        path.length < 256 && %r{\A/v\d+/(\w+/?)+\z}.match(path)
      end

      private

      def _parse_path
        _, version, *pieces = path.split(/\/+/)
        @version = version.downcase.to_sym
        @object_chain = pieces.map(&:freeze)
      end
    end # Request
  end # Service
end # Rester
