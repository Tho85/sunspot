module Sunspot
  # 
  # This class encapsulates the search/indexing setup for a given class. Its
  # contents are built using the Sunspot.setup method.
  #
  class Setup #:nodoc:
    def initialize(clazz)
      @class_name = clazz.name
      @field_factories, @text_field_factories, @dynamic_field_factories = {}, {}, {}
      @dsl = DSL::Fields.new(self)
    end

    # 
    # Add field_factories for scope/ordering
    # 
    # ==== Parameters
    #
    # field_factories<Array>:: Array of Sunspot::Field objects
    #
    def add_field_factory(name, type, options = {}, &block)
      field_factory = FieldFactory::Static.new(name, type, options, &block)
      @field_factories[field_factory.signature] = field_factory
    end

    # 
    # Add field_factories for fulltext search
    #
    # ==== Parameters
    #
    # field_factories<Array>:: Array of Sunspot::Field objects
    #
    def add_text_field_factory(name, options = {}, &block)
      field_factory = FieldFactory::Static.new(name, Type::TextType, options, &block)
      @text_field_factories[name] = field_factory
    end

    #
    # Add dynamic field_factories
    #
    # ==== Parameters
    # 
    # field_factories<Array>:: Array of dynamic field objects
    # 
    def add_dynamic_field_factory(name, type, options = {}, &block)
      field_factory = FieldFactory::Dynamic.new(name, type, options, &block)
      @dynamic_field_factories[field_factory.signature] = field_factory
    end

    # 
    # Builder method for evaluating the setup DSL
    #
    def setup(&block)
      @dsl.instance_eval(&block)
    end

    def fields
      field_factories.map { |field_factory| field_factory.build }
    end

    def text_fields
      text_field_factories.map { |field_factory| text_field_factory.build }
    end

    # 
    # Get the field_factories associated with this setup as well as all inherited field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all field_factories associated with this setup
    #
    def field_factories
      collection_from_inheritable_hash(:field_factories)
    end

    # 
    # Get the text field_factories associated with this setup as well as all inherited
    # text field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all text field_factories associated with this setup
    #
    def text_field_factories
      collection_from_inheritable_hash(:text_field_factories)
    end

    # 
    # Get all static, dynamic, and text field_factories associated with this setup as
    # well as all inherited field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all text and scope field_factories associated with this setup
    #
    def all_field_factories
      all_field_factories = []
      all_field_factories.concat(field_factories).concat(text_field_factories).concat(dynamic_field_factories)
      all_field_factories
    end

    # 
    # Get all dynamic field_factories for this and parent setups
    # 
    # ==== Returns
    #
    # Array:: Dynamic field_factories
    #
    def dynamic_field_factories
      collection_from_inheritable_hash(:dynamic_field_factories)
    end

    # 
    # Factory method for an Indexer object configured to use this setup
    #
    # ==== Returns
    #
    # Sunspot::Indexer:: Indexer configured with this setup
    #
    def indexer(connection)
      Indexer.new(connection, self)
    end

    # 
    # Return the class associated with this setup.
    #
    # ==== Returns
    #
    # clazz<Class>:: Class setup is configured for
    #
    def clazz
      Util.full_const_get(@class_name)
    end

    protected

    # 
    # Get the nearest inherited setup, if any
    #
    # ==== Returns
    # 
    # Sunspot::Setup:: Setup for the nearest ancestor of this setup's class
    #
    def parent
      Setup.for(clazz.superclass)
    end

    def get_inheritable_hash(name)
      hash = instance_variable_get(:"@#{name}")
      parent.get_inheritable_hash(name).each_pair do |key, value|
        hash[key] = value unless hash.has_key?(key)
      end if parent
      hash
    end

    private

    def collection_from_inheritable_hash(name)
      get_inheritable_hash(name).values
    end

    class <<self
      # 
      # Retrieve or create the Setup instance for the given class, evaluating
      # the given block to add to the setup's configuration
      #
      def setup(clazz, &block) #:nodoc:
        self.for!(clazz).setup(&block)
      end

      # 
      # Retrieve the setup instance for the given class, or for the nearest
      # ancestor that has a setup, if any.
      #
      # ==== Parameters
      #
      # clazz<Class>:: Class for which to retrieve a setup
      #
      # ==== Returns
      #
      # Sunspot::Setup::
      #   Setup instance associated with the given class or its nearest ancestor
      #   
      def for(clazz) #:nodoc:
        setups[clazz.name.to_sym] || self.for(clazz.superclass) if clazz
      end

      protected

      # 
      # Retrieve or create a Setup instance for this class
      #
      # ==== Parameters
      #
      # clazz<Class>:: Class for which to retrieve a setup
      #
      # ==== Returns
      #
      # Sunspot::Setup:: New or existing setup for this class
      #
      def for!(clazz) #:nodoc:
        setups[clazz.name.to_sym] ||= new(clazz)
      end

      private

      # Singleton hash of class names to Setup instances
      #
      # ==== Returns
      #
      # Hash:: Class names keyed to Setup instances
      #
      def setups
        @setups ||= {}
      end
    end
  end
end
