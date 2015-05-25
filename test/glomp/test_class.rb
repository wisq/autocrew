require 'glomp'

class GlompTestClass
  include Glomp::Glompable

  attr_accessor :value, :ref

  def initialize(value, ref)
    @value = value
    @ref = ref
  end

  def to_hash
    return {
      'value' => @value,
      'ref' => @ref,
    }
  end

  def self.from_hash(hash)
    new(hash['value'], hash['ref'])
  end
end
