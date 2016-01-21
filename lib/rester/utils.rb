require 'date'
require 'uri'

module Rester
  module Utils
    autoload(:StubFile,       'rester/utils/stub_file')
    autoload(:RSpec,          'rester/utils/rspec')
    autoload(:CircuitBreaker, 'rester/utils/circuit_breaker')
    autoload(:LoggerWrapper,  'rester/utils/logger_wrapper')

    class << self
      ##
      # Determines the HTTP method/verb based on the method name.
      # Defaults to GET but if the method ends with "!" it uses POST.
      def extract_method_verb(meth)
        meth = meth.to_s

        if meth[-1] == '!'
          [:post, meth[0..-2]]
        else
          [:get, meth]
        end
      end

      ##
      # Copied from Rack::Utils.build_nested_query (version 1.6.0)
      #
      # We want to be able to support Rack >= 1.5.2, but this method is broken
      # in that version.
      def encode_www_data(value, prefix = nil)
        # Rack::Utils.build_nested_query(value)
        case value
        when Array
          value.map { |v|
            encode_www_data(v, "#{prefix}[]")
          }.join("&")
        when Hash
          value.map { |k, v|
            encode_www_data(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          }.reject(&:empty?).join('&')
        when nil
          prefix
        else
          raise ArgumentError, "value must be a Hash" if prefix.nil?
          "#{prefix}=#{escape(value)}"
        end
      end

      def decode_www_data(data)
        Rack::Utils.parse_nested_query(data)
      end

      def escape(value)
        URI.encode_www_form_component(value)
      end

      def join_paths(*paths)
        paths.map(&:to_s).reject { |p| p.nil? || p.empty? }
          .join('/').gsub(/\/+/, '/')
      end

      def walk(object, context=nil, &block)
        case object
        when Hash
          Hash[
            object.map { |key, val|
              [walk(key, :hash_key, &block), walk(val, :hash_value, &block)]
            }
          ]
        when Array
          object.map { |obj| walk(obj, :array_elem, &block) }
        when Range
          Range.new(
            walk(object.begin, :range_begin, &block),
            walk(object.end, :range_end, &block),
            object.exclude_end?
          )
        else
          yield object, context
        end
      end

      def symbolize_keys(hash)
        hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

      ##
      # Converts all keys and values to strings.
      def stringify(hash={})
        decode_www_data(encode_www_data(hash))
      end

      def classify(str)
        str.to_s.split("_").map(&:capitalize).join
      end

      def underscore(str)
        str.scan(/[A-Z][a-z]*/).map(&:downcase).join('_')
      end

      def deep_freeze(value)
        value.freeze

        case value
        when Hash
          value.values.each { |v| deep_freeze(v) }
        when Array
          value.each { |v| deep_freeze(v) }
        end
      end
    end # Class methods
  end # Utils
end # Rester
