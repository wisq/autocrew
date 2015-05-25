require 'json'

module Glomp
  class ObjectRegistry
    class RegisterMismatchError < StandardError; end
    class RegisterCollisionError < StandardError; end

    def initialize
      @by_id = {}
      @by_object = {}
      @next_id = 0
    end

    def register(object, id = nil)
      if old_id = @by_object[object]
        return if id == nil || id == old_id
        raise RegisterMismatchError.new("Attempt to re-register object #{object.inspect} with new ID (#{old_id} vs #{id})")
      end

      id ||= (@next_id += 1)

      if old_object = @by_id[id]
        return if old_object.eql?(object)
        raise RegisterCollisionError.new("ID #{id} already taken by #{old_object.inspect}, cannot assign to #{object.inspect}")
      end

      @by_id[id] = object
      @by_object[object] = id
    end

    def lookup(id)
      @by_id[id]
    end
  end
end
