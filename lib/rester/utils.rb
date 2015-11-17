require 'date'

module Rester
  module Utils
    autoload(:StubFile,  'rester/utils/stub_file')

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

      def stringify_vals(hash={})
        hash.inject({}) { |memo,(k,v)|
          case v
          when Hash
            memo[k] = stringify_vals(v)
          else
            memo[k] = v.to_s
          end
          memo
        }
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
