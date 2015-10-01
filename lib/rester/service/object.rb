require 'rack'
require 'active_support/inflector'

module Rester
  class Service
    class Object
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

        def process(request_method, params={})
          meth = REQUEST_METHOD_TO_CLASS_METHOD[request_method]

          if respond_to?(meth)
            public_send(meth, params)
          else
            raise Errors::NotFoundError, meth
          end
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

        if respond_to?(meth)
          public_send(meth, params)
        else
          raise Errors::NotFoundError, meth
        end
      end

      def mounts
        self.class.mounts
      end
    end # Object
  end # Service
end # Rester
