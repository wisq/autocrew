require 'set'
require 'json'
require 'glomp/glompable'
require 'glomp/object_registry'

module Glomp
  class Glomper
    class CircularReferenceError < StandardError; end

    def glomp(object)
      @registry = ObjectRegistry.new
      @objects = {}
      @stack = Set.new

      root = make_reference(object)

      return {
        objects: @objects,
        root: root
      }.to_json
    end

    def make_reference(object)
      id = @registry.register(object)

      unless @objects.has_key?(id)
        @objects[id] = dump_object(object, id)
      end

      return id
    end

    def dump_object(object, id)
      raise CircularReferenceError if @stack.include?(id)
      @stack << id

      data = {}
      object.to_hash.each do |key, value|
        data[key] = dump_value(value)
      end

      return {
        class: object.class,
        id: id,
        data: data
      }
    end

    CLASS_WHITELIST = [NilClass, TrueClass, FalseClass, String, Numeric]

    def dump_value(value)
      if value.kind_of? Glompable
        return {'glomper_reference': make_reference(value)}
      elsif value.kind_of? Hash
        out = {}
        object.to_hash.each { |k, v| out[k] = dump_value(v) }
        return out
      else
        CLASS_WHITELIST.each do |cls|
          return value if value.kind_of?(cls)
        end
        raise "Unglompable value: #{value.inspect} (#{value.class})"
      end
    end
  end
end
