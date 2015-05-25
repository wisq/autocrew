require 'set'
require 'json'
require 'glomp/object_registry'

module Glomp
  class Unglomper
    def unglomp(json)
      @registry = ObjectRegistry.new
      hash = JSON.load(json)
      @objects = hash['objects']
      @stack = Set.new

      return follow_reference(hash['root'])
    end

    def follow_reference(id)
      if object = @registry.lookup(id)
        return object
      elsif @stack.include?(id)
        raise CircularReferenceError
      else
        @stack << id
      end

      obj_hash = @objects[id.to_s]
      obj_class = find_class(obj_hash['class'])
      data = load_data(obj_hash['data'])

      object = obj_class.from_hash(data)
      raise "obj_class.from_hash did not return a #{obj_class}: #{object.inspect}" unless object.kind_of?(obj_class)

      @registry.register(object, obj_hash['id'])
      return object
    end

    def load_data(data)
      if data.kind_of? Hash
        if data.keys == ['glomper_reference']
          return follow_reference(data['glomper_reference'])
        end

        out = {}
        data.each do |key, value|
          out[key] = load_data(value)
        end
        return out
      else
        return data
      end
    end

    def find_class(name)
      cls = Object
      name.split('::').each do |part|
        new_cls = cls.const_get(name)
        raise "#{cls}::#{part} is not a class or module" unless new_cls.kind_of? Module
        cls = new_cls
      end

      raise "#{cls} is not Glompable" unless cls.include? Glompable
      return cls
    end
  end
end
