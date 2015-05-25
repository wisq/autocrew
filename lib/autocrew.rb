module Autocrew
  class JSONable
    def to_json(state=nil)
      to_hash.to_json(state)
    end

    def self.from_json(json)
      from_hash(JSON.load(json))
    end
  end
end
