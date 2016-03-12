module Rester
  class Service::Resource
    class Params
      DEFAULT_OPTS = { strict: true }.freeze
      BASIC_TYPES = [String, Symbol, Float, Integer, Array, Hash].freeze

      DEFAULT_TYPE_MATCHERS = {
        Integer  => /\A\d+\z/,
        Float    => /\A\d+(\.\d+)?\z/,
        :boolean => /\A(true|false)\z/i
      }.freeze

      attr_reader :options

      def initialize(opts={}, &block)
        @options = DEFAULT_OPTS.merge(opts).freeze
        @_dynamic_fields = []
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
        @_dynamic_fields.freeze
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

        _validate_strict(param_keys)

        validated_params = Hash[
          params.map { |key, value| [key.to_sym, validate!(key.to_sym, value)] }
        ]

        @_defaults.merge(validated_params)
      end

      def validate!(key, value)
        if @_validators.key?(key)
          klass, opts = @_validators[key]
        else
          dynamic_key = @_dynamic_fields.find { |r| r.match(key) }
          klass, opts = @_validators[dynamic_key]
        end

        _validate(key, value, klass, opts)
      end

      def use(params)
        _merge_params(params)
        nil
      end

      def required?(key)
        @_required_fields.include?(key.to_sym)
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
        define_method(type.to_s) { |name, opts={}, &block|
          if type == Hash || (type == Array && opts[:type] == Hash)
            elem_type = (options = @options.merge(opts)).delete(:type)
            opts = elem_type ? { type: elem_type } : {}
            opts.merge!(use: self.class.new(options, &block))
          end

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

      def dynamic_fields
        @_dynamic_fields.dup
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
        default_opts = { match: DEFAULT_TYPE_MATCHERS[klass] }
        opts = default_opts.merge(opts)

        if name.is_a?(Regexp)
          @_dynamic_fields << name
        else
          name = name.to_sym
          @_required_fields << name if opts.delete(:required)
          default = opts.delete(:default)
        end

        @_all_fields << name
        @_validators[name] = [klass, opts]

        if name.is_a?(Symbol) && default
          _validate_default(name, default)
          @_defaults[name] = default
        end

        nil
      end

      def _validate_strict(keys)
        if strict?
          unexpected = (keys - @_all_fields).reject do |k|
            @_dynamic_fields.find { |f| f.match(k) }
          end

          unless unexpected.empty?
            _error!("unexpected params: #{unexpected.join(', ')}")
          end
        end
      end

      ##
      # Validates a default value specified in the params block. Raises
      # validation error if necessary.
      def _validate_default(key, default)
        error = catch(:error) do
          type = @_validators[key].first

          unless _valid_type?(default, type)
            # The .camelcase here is for when type = 'boolean'
            _error!("default for #{key} should be of "\
              "type #{type.to_s.camelcase}")
          end

          validate!(key.to_sym, default.to_s)
          nil
        end

        raise error if error
      end

      ##
      # Validates and parses a given value. `klass` is the intended type for the
      # value (e.g., String, Integer, Array, etc.). `opts` contains the
      # validation options.
      def _validate(key, value, klass, opts)
        case value
        when String
          _validate_str(key, value, klass, opts)
        when Array
          _validate_array(key, value, klass, opts)
        when Hash
          _validate_hash(key, value, klass, opts)
        when NilClass
          _validate_required(key, false)
        else
          _error!("unexpected value type for #{key}: #{value.class}")
        end
      end

      def _validate_str(key, value, klass, opts)
        fail unless value.is_a?(String) # assert
        if [Array, Hash].include?(klass)
          _error!("expected #{key} to be of type #{klass}")
        end

        _validate_match(key, value, opts[:match]) if opts[:match]
        _parse_with_class(klass, value).tap do |obj|
          _validate_type(key, obj, klass) if obj
          _validate_obj(key, obj, opts)
        end
      end

      def _validate_array(key, value, klass, opts)
        _error!("unexpected Array for #{key}") unless klass == Array
        type = (opts = opts.dup).delete(:type) || String

        value.each_with_index
          .map { |e, i| _validate("#{key}[#{i}]", e, type, opts) }
      end

      def _validate_hash(key, value, klass, opts)
        _error!("unexpected Hash for #{key}") unless klass == Hash
        (validator = opts[:use]) && validator.validate(value)
      end

      def _parse_with_class(klass, value)
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

      def _validate_obj(key, obj, opts)
        fail if obj.nil? # Assert, at this point should be guaranteed

        opts.each do |opt, value|
          case opt
          when :within
            _validate_within(key, obj, value)
          when :match
            # Nop - This is evaluated before the incoming string is parsed.
          else
            _validate_method(key, obj, opt, value) unless obj.nil?
          end
        end
      end

      def _validate_type(key, obj, type)
        unless _valid_type?(obj, type)
          # The .camelcase here is for when type = 'boolean'
          _error!("#{key} should be #{type.to_s.camelcase} but "\
            "got #{obj.class}")
        end
      end

      def _validate_required(key, is_defined)
        unless is_defined
          _, key, index = /(\w+)(\[\d+\])?/.match(key).to_a

          if required?(key)
            if index
              _error!("#{key} cannot contain null elements")
            else
              _error!("#{key} cannot be null")
            end
          end
        end
      end

      def _valid_type?(obj, type)
        case type
        when :boolean
          obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
        else
          obj.is_a?(type)
        end
      end

      ##
      # To be called *before* the incoming string is parsed into the object.
      def _validate_match(key, str, matcher)
        unless matcher.match(str)
          _error!("#{key} does not match #{matcher.inspect}")
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
        @_dynamic_fields  |= params.dynamic_fields
        @_all_fields      |= params.all_fields
      end
    end
  end
end
