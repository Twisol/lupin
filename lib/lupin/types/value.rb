module Lupin::Types
  # Base class for all Lua values
  class Value
    attr_reader :value
    
    def initialize (value)
      @value = value
    end
    
    def inspect
      @value.inspect
    end
    
    def to_s
      inspect
    end
    
    def to_bool
      @value ? true : false
    end
    
    def + (other)
    end
    
    def - (other)
    end
    
    def * (other)
    end
    
    def / (other)
    end
    
    def % (other)
    end
    
    def ** (other)
    end
    
    def -@ (other)
    end
    
    def == (other)
    end
    
    def <= (other)
      other <= self
    end
    
    def < (other)
      other < self
    end
    
    def concatenate (other)
    end
  end
end
