module Lupin::Types
  class Number < Value
    def self.math_op (*ops)
      ops.each do |op|
        define_method(op) do |other|
          math(op, other) or super
        end
      end
    end
    
    math_op :+, :-, :*, :/, :%, :**, :-@

  private
    def math (op, other)
      # Attempt to coerce a string into a number
      other = other.to_number if other.is_a? String
      # Then do the math if 'other' is a number.
      Number(@value.send(op, other.value)) if other.is_a? Number
      # If 'other' simple isn't a number, nil is returned.
    end
  end
end
