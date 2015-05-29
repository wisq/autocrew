$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'autocrew'

require 'minitest/autorun'
require 'mocha/mini_test'

class Minitest::Test
  class << self # The def self.test way of doing it doesn't override Kernel.test but this does...
    def test(name, &block)
      method_name = "test_#{ name.gsub(/[\W]/, '_') }"
      if block.nil?
        define_method(method_name) do
          flunk "Missing implementation for test #{name.inspect}"
        end
      else
        define_method(method_name, &block)
      end
    end
  end

  def assert_coord(x, y, coord, delta=0.001)
    assert_in_delta x, coord.x, delta, "Mismatch (X) between #{[x,y]} and #{[coord.x,coord.y]}"
    assert_in_delta y, coord.y, delta, "Mismatch (Y) between #{[x,y]} and #{[coord.x,coord.y]}"
  end
end
