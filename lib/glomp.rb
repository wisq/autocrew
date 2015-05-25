require 'glomp/glomper'
require 'glomp/unglomper'

module Glomp
  def self.glomp(object)
    Glomper.new.glomp(object)
  end

  def self.unglomp(json)
    Unglomper.new.unglomp(json)
  end
end
