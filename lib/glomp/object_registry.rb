require 'json'

module Glomp
  class ObjectRegistry
    def initialize
      @by_id = {}
      @by_object = {}
      @next_id = 0
    end

    def register(object, id = nil)
      if old_id = @by_object[object]
        return if id == nil || id == old_id
        raise "Attempt to re-register object #{object.inspect} with new ID (#{old_id} vs #{id})"
      end

      id ||= (@next_id += 1)
      @by_id[id] = object
      @by_object[object] = id
    end

    def lookup(id)
      @by_id[id]
    end

    def registered?(object)
      @by_object.has_key?(object)
    end
  end
end
