require_relative 'dsl'
require_relative 'schema'

module JSON
  module SchemaBuilder
    class Entity
      include DSL
      class_attribute :registered_type
      attr_accessor :name, :parent

      def self.attribute(name, array: false)
        as_name = name.to_s.underscore.gsub(/_(\w)/){ $1.upcase }
        define_method name do |*values|
          value = array ? values.flatten : values.first
          if (array && value.empty?) || value.nil?
            self.schema[as_name]
          else
            self.schema[as_name] = value
          end
        end
        alias_method "#{ name }=", name
      end

      attribute :title
      attribute :description

      attribute :type
      attribute :enum, array: true
      attribute :all_of, array: true
      attribute :any_of, array: true
      attribute :one_of, array: true
      attribute :not
      attribute :definitions

      def initialize(name, opts = { }, &block)
        @name = name
        self.type = self.class.registered_type
        initialize_parent_with opts
        initialize_with opts
        eval_block &block
      end

      def schema
        @schema ||= Schema.new
      end

      def required=(*values)
        @parent.required ||= []
        @parent.required << @name
      end

      def enum=(*values)
        @schema.enum = values.flatten
      end

      def as_json
        schema.to_h.as_json
      end

      protected

      def initialize_parent_with(opts)
        @parent = opts.delete :parent
        @parent.children << self if @parent
      end

      def initialize_with(opts)
        opts.each_pair do |key, value|
          next if value.nil?
          send :"#{ key }=", value
        end
      end

      def eval_block(&block)
        instance_exec(self, &block) if block_given?
      end
    end
  end
end
