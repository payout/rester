require 'rack'
require 'active_support/inflector'

module Rester
  class Service
    class Resource
      autoload(:Validator, 'rester/service/resource/validator')

      REQUEST_METHOD_TO_IDENTIFIED_METHOD = {
        'GET'    => :get,
        'PUT'    => :update,
        'DELETE' => :delete
      }.freeze

      REQUEST_METHOD_TO_UNIDENTIFIED_METHOD = {
        'GET'    => :search,
        'POST'   => :create
      }.freeze

      ########################################################################
      # DSL
      ########################################################################
      class << self
        ##
        # Specify the name of your identifier (Default: 'id')
        def id(name)
          @id_name = name.to_sym
        end

        ##
        # Mount another Service Resource
        def mount(klass)
          raise "Only other Service Resources can be mounted." unless klass < Resource
          start = self.name.split('::')[0..-2].join('::').length + 2
          mounts[klass.name[start..-1].pluralize.underscore] = klass
        end

        def params(opts={}, &block)
          (@_validator = Validator.new(opts)).instance_eval(&block)
          @_validator.freeze
        end
      end # DSL

      ########################################################################
      # Class Methods
      ########################################################################
      class << self
        def id_name
          @id_name ||= :id
        end

        def id_param
          "#{self.name.split('::').last.underscore}_#{id_name}"
        end

        def mounts
          (@__mounts ||= {})
        end

        def validator
          @_validator ||= Validator.new
        end
      end # Class Methods

      def id_param
        self.class.id_param
      end

      ##
      # Given an HTTP request method, calls the appropriate calls the
      # appropriate instance method. `id_provided` specifies whether on not the
      # ID for the object is included in the params hash. This will be used when
      # determining which instance method to call. For example, if the request
      # method is GET: the ID being specified will call the `get` method and if
      # it's not specified then it will call the `search` method.
      def process(request_method, id_provided, params={})
        meth = (id_provided ? REQUEST_METHOD_TO_IDENTIFIED_METHOD
          : REQUEST_METHOD_TO_UNIDENTIFIED_METHOD)[request_method]

        _process(meth, params).to_h
      end

      def mounts
        self.class.mounts
      end

      def validator
        self.class.validator
      end

      def error!(message=nil)
        Errors.throw_error!(Errors::RequestError, message)
      end

      private

      ##
      # Calls the specified method, passing the params if the method accepts
      # an argument. Allows for the arity of the method to be 0, 1 or -1.
      def _process(meth, params)
        if meth && respond_to?(meth)
          params = validator.validate(params)
          meth = method(meth)

          case meth.arity.abs
          when 1
            meth.call(params)
          when 0
            meth.call
          else
            fail MethodDefinitionError, "#{meth} must take 0 or 1 argument"
          end
        else
          fail Errors::NotFoundError, meth
        end
      end
    end # Resource
  end # Service
end # Rester
