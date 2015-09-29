require 'date'

module Restercom
  module Utils
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

      def classify(str)
        str.to_s.split("_").map(&:capitalize).join
      end
    end # Class methods
  end # Utils
end # Restercom
