module Lupin::Types
  # Base class for all Lua values
  class Value
    attr_reader :value
    
    def initialize (value)
      @value = value
    end
    
    def inspect
      to_s
    end
    
    def to_s
      @value.to_s
    end
    
    def to_bool
      @value ? true : false
    end
    
    def math_op (sym, other)
      raise "Metatables not implemented yet"
    end
    
    def == (other)
      self.is_a?(other.class) && @value == other.value
    end
  end
end
