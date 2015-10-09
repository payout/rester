module Rester
  class Service::Object
    class Validator
      BASIC_TYPES = [String, Symbol, Float, Integer].freeze

      attr_reader :options

      def initialize(opts={})
        @options = opts.dup.freeze
        @_required_fields = []
        @_all_fields = []

        # Default "validator" is to just treat the param as a string.
        @_validators = Hash.new([String, {}])
      end

      ##
      # Whether or not validation will be done strictly (i.e., only specified
      # params will be allowed).
      def strict?
        !!options[:strict]
      end

      def freeze
        @_validators.freeze
        @_required_fields.freeze
        @_all_fields.freeze
      end

      def required_params
        @_required_fields.dup
      end

      def validate(params)
        param_keys = params.keys.map(&:to_sym)

        unless (missing = @_required_fields - param_keys).empty?
          _error!("missing params: #{missing.join(', ')}")
        end

        if strict? && !(unexpected = param_keys - @_all_fields).empty?
          _error!("unexpected params: #{unexpected.join(', ')}")
        end

        params.map do |key, value|
          [key.to_sym, validate!(key.to_sym, value)]
        end.to_h
      end

      def validate!(key, value)
        klass, opts = @_validators[key]

        _parse_with_class(klass, value).tap do |obj|
          if obj.nil? && @_required_fields.include?(key)
            _error!("#{key} cannot be null")
          end

          opts.each do |opt, value|
            case opt
            when :within
              _validate_within(key, obj, value)
            else
              _validate_method(key, obj, opt, value) unless obj.nil?
            end
          end
        end
      end

      ##
      # The basic data types all have helper methods named after them in Kernel.
      # This allows you to do things like String(1234) to get '1234'. It's the
      # same as doing 1234.to_s.
      #
      # Since methods already exist globally for these types, we need to override
      # them so we can capture their calls. If this weren't the case, then we'd
      # be catch them in `method_missing`.
      BASIC_TYPES.each do |type|
        define_method(type.to_s) { |name, opts={}|
          _add_validator(name, type, opts)
        }
      end

      ##
      # Need to have special handling for Boolean since Ruby doesn't have a
      # Boolean type, instead it has TrueClass and FalseClass...
      def Boolean(name, opts={})
        _add_validator(name, :boolean, opts)
      end

      private

      def method_missing(meth, *args)
        meth_str = meth.to_s

        if meth.to_s.match(/\A[A-Z][A-Za-z]+\z/)
          name = args.shift
          opts = args.shift || {}
          _add_validator(name, self.class.const_get(meth), opts)
        end
      end

      def _add_validator(name, klass, opts)
        fail 'must specify param name' unless name
        fail 'validation options must be a Hash' unless opts.is_a?(Hash)
        opts = opts.dup
        @_required_fields << name.to_sym if opts.delete(:required)
        @_all_fields << name.to_sym
        @_validators[name.to_sym] = [klass, opts]
        nil
      end

      def _parse_with_class(klass, value)
        return nil if value == 'null'

        if klass == String
          value
        elsif klass == Integer
          value.to_i
        elsif klass == Float
          value.to_f
        elsif klass == Symbol
          value.to_sym
        elsif klass == :boolean
          value.downcase == 'true' ? true : false
        else
          klass.parse(value)
        end
      end

      def _validate_within(key, obj, value)
        unless value.include?(obj)
          _error!("#{key} not within #{value.inspect}")
        end
      end

      def _validate_method(key, obj, opt, value)
        unless (meth = obj.respond_to?(opt) && obj.method(opt))
          _error!("#{key} does not respond to #{opt.inspect}")
        end

        unless meth.call(*value)
          _error!("#{key} failed #{opt}(#{[value].flatten.join(',')}) validation")
        end
      end

      def _error!(message)
        Errors.throw_error!(Errors::ValidationError, message)
      end
    end
  end
end
