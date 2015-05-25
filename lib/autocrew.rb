module Autocrew
  class JSONable
    def to_json(state=nil)
      to_hash.to_json(state)
    end

    def self.from_json(json, lookup = nil)
      hash = JSON.load(json)
      if method(:from_hash).arity == 2
        raise "lookup object required" unless lookup
        from_hash(hash, lookup)
      else
        from_hash(hash)
      end
    end
  end
end
