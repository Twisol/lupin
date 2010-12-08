module Lupin::Types
  # Base class for all Lua values
  class Value
    attr_reader :value
    protected :value
    
    def initialize (value)
      @value = value
    end
    
    def to_s
      @value.inspect
    end
    
    def to_bool
      @value ? true : false
    end
    
    def + (other)
      Nil
    end
    
    def - (other)
      Nil
    end
    
    def * (other)
      Nil
    end
    
    def / (other)
      Nil
    end
    
    def % (other)
      Nil
    end
    
    def ** (other)
      Nil
    end
    
    def -@ (other)
      Nil
    end
    
    def == (other)
      case other
      when self.class
        Boolean.new(@value.equal?(other.value)) # TODO: check metatable for __eq
      when Value
        False
      else
        super
      end
    end
    
    # Ruby 1.8 doesn't recognize != as a method name
    def not_equal (other)
      Boolean.new(!(self == other).to_bool)
    end
    
    def <= (other)
      case other
      when Value
        False # TODO: check metatable for __le
      else
        super
      end
    end
    
    def >= (other)
      other <= self
    end
    
    def < (other)
      case other
      when Value
        False # TODO: check metatable for __lt
      else
        super
      end
    end
    
    def > (other)
      other < self
    end
    
    def concatenate (other)
      Nil
    end
  end
end
