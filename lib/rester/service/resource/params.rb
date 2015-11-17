module Rester
  class Service::Resource
    class Params
      DEFAULT_OPTS = { strict: true }.freeze
      BASIC_TYPES = [String, Symbol, Float, Integer].freeze

      attr_reader :options

      def initialize(opts={}, &block)
        @options = DEFAULT_OPTS.merge(opts).freeze
        @_required_fields = []
        @_defaults = {}
        @_all_fields = []

        # Default "validator" is to just treat the param as a string.
        @_validators = Hash.new([String, {}])

        instance_eval(&block) if block_given?
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
        @_defaults.freeze
        @_all_fields.freeze
        super
      end

      def validate(params)
        param_keys = params.keys.map(&:to_sym)
        default_keys = @_defaults.keys

        unless (missing = @_required_fields - param_keys - default_keys).empty?
          _error!("missing params: #{missing.join(', ')}")
        end

        if strict? && !(unexpected = param_keys - @_all_fields).empty?
          _error!("unexpected params: #{unexpected.join(', ')}")
        end

        validated_params = params.map do |key, value|
          [key.to_sym, validate!(key.to_sym, value)]
        end.to_h

        @_defaults.merge(validated_params)
      end

      def validate!(key, value)
        klass = @_validators[key].first

        _parse_with_class(klass, value).tap do |obj|
          _validate_obj(key, obj)
        end
      end

      def use(params)
        _merge_params(params)
        nil
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

      protected

      def required_params
        @_required_fields.dup
      end

      def defaults
        @_defaults.dup
      end

      def all_fields
        @_all_fields.dup
      end

      def validators
        @_validators.dup
      end

      private

      def method_missing(meth, *args)
        meth_str = meth.to_s

        if meth.to_s.match(/\A[A-Z][A-Za-z]+\z/)
          name = args.shift
          opts = args.shift || {}
          _add_validator(name, self.class.const_get(meth), opts)
        else
          super
        end
      end

      def _add_validator(name, klass, opts)
        fail 'must specify param name' unless name
        fail 'validation options must be a Hash' unless opts.is_a?(Hash)
        opts = opts.dup

        @_required_fields << name.to_sym if opts.delete(:required)
        default = opts.delete(:default)

        @_all_fields << name.to_sym
        @_validators[name.to_sym] = [klass, opts]

        if default
          _validate_default(name.to_sym, default)
          @_defaults[name.to_sym] = default
        end

        nil
      end

      def _validate_default(key, default)
        error = catch(:error) { _validate_obj(key.to_sym, default) }
        raise error if error
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

      def _validate_obj(key, obj)
        if obj.nil? && @_required_fields.include?(key)
          _error!("#{key} cannot be null")
        end

        klass, opts = @_validators[key]
        _validate_type(key, obj, klass) if obj

        opts.each do |opt, value|
          case opt
          when :within
            _validate_within(key, obj, value)
          else
            _validate_method(key, obj, opt, value) unless obj.nil?
          end
        end

        nil
      end

      def _validate_type(key, obj, type)
        case type
        when :boolean
          unless obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
            _error!("#{key} should be Boolean but got #{obj.class}")
          end
        else
          unless obj.is_a?(type)
            _error!("#{key} should be #{type} but got #{obj.class}")
          end
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

      def _merge_params(params)
        @_validators       = @_validators.merge!(params.validators)
        @_defaults         = @_defaults.merge!(params.defaults)
        @_required_fields |= params.required_params
        @_all_fields      |= params.all_fields
      end
    end
  end
end
