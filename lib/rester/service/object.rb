require 'rack'
require 'active_support/inflector'

module Rester
  class Service
    class Object
      autoload(:Validator, 'rester/service/object/validator')

      REQUEST_METHOD_TO_INSTANCE_METHOD = {
        'GET'    => :get,
        'PUT'    => :update,
        'DELETE' => :delete
      }.freeze

      REQUEST_METHOD_TO_CLASS_METHOD = {
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
          (@id_name = name.to_sym).tap { |name|
            # Create the accessor method for the ID.
            define_method(name) { @id } unless name == :id
          }
        end

        ##
        # Mount another Service Object
        def mount(klass)
          raise "Only other Service Objects can be mounted." unless klass < Object
          start = self.name.split('::')[0..-2].join('::').length + 2
          mounts[klass.name[start..-1].underscore] = klass
        end

        def params(opts={}, &block)
          (@_validator ||= Validator.new(opts)).instance_eval(&block)
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
          @_validator
        end

        ##
        # Helper method called at the class and instance level that calls the
        # specified method on the passed object with the params. Allows for
        # the arity of the method to be 0, 1 or -1.
        def process!(obj, meth, params)
          if obj.respond_to?(meth)
            params = validator.validate(params)
            meth = obj.method(meth)

            case meth.arity.abs
            when 1
              meth.call(params)
            when 0
              meth.call
            else
              raise MethodDefinitionError, "#{meth} must take 0 or 1 argument"
            end
          else
            raise Errors::NotFoundError, meth
          end
        end

        def process(request_method, params={})
          meth = REQUEST_METHOD_TO_CLASS_METHOD[request_method]
          process!(self, meth, params)
        end
      end # Class Methods

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def id_param
        self.class.id_param
      end

      def process(request_method, params={})
        meth = REQUEST_METHOD_TO_INSTANCE_METHOD[request_method]
        self.class.process!(self, meth, params)
      end

      def mounts
        self.class.mounts
      end
    end # Object
  end # Service
end # Rester
