module Lupin::Types
  class Number < Value
    def self.math_op (*ops)
      ops.each do |op|
        define_method(op) do |other|
          math(op, other) or super
        end
      end
    end
    
    def to_s
      sprintf("%.14g", @value)
    end
    
    math_op :+, :-, :*, :/, :%, :**, :-@
    
    def == (other)
      if other.is_a? Number
        Boolean.new(@value == other.value)
      else
        super
      end
    end
    
    def <= (other)
      if other.is_a? Number
        Boolean.new(@value <= other.value)
      else
        super
      end
    end
    
    def < (other)
      if other.is_a? Number
        Boolean.new(@value < other.value)
      else
        super
      end
    end
    
    def concatenate (other)
      if other.is_a? String
        String.new(to_s).concatenate(other)
      else
        super
      end
    end

  private
    def math (op, other)
      # Attempt to coerce a string into a number
      other = other.to_number if other.is_a? String
      if other.is_a? Number
        Number.new(@value.send(op, other.value))
      else
        Nil
      end
    end
  end
end
