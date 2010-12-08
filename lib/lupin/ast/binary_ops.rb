module Lupin::AST
  # Base class for all binary operations.
  class BinaryOp
    def initialize (lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end
    
    # Helper method for defining binary operations
    def self.for (sym)
      # Create a sublass of BinaryOp
      op = Class.new(self) do
        def bytecode (g)
          @lhs.bytecode(g)
          @rhs.bytecode(g)
          g.send self.class::OP, 1
        end
        
        def sexp
          [self.class::OP, @lhs.sexp, @rhs.sexp]
        end
      end
      
      # Store the operation symbol as a constant on the new class.
      op.const_set :OP, sym
      op
    end
  end
  
  
  ###
  # Simple operations
  ###
  Addition       = BinaryOp.for :+
  Subtraction    = BinaryOp.for :-
  Multiplication = BinaryOp.for :*
  Division       = BinaryOp.for :/
  Modulo         = BinaryOp.for :%
  Power          = BinaryOp.for :**
  Concatenate    = BinaryOp.for :concatenate
  
  ###
  # Relational operations
  ###
  Equal    = BinaryOp.for :==
  AtMost   = BinaryOp.for :<=
  AtLeast  = BinaryOp.for :>=
  LessThan = BinaryOp.for :<
  MoreThan = BinaryOp.for :>
  
  
  ###
  # Logical operations
  ###
  class LogicalOp < BinaryOp
    def bytecode(g)
      else_label = g.new_label
      done_label = g.new_label
      
      @lhs.bytecode(g)
      
      # Duplicate the left operand so we branch based on it.
      g.dup
      g.send :to_bool, 0
      
      # Decide when the operator should short-circuit.
      if @stop_on_false then
        g.git else_label # Stop on false
      else
        g.gif else_label # Stop on true
      end
        # Use the left operand as our result value.
        # It's already on the stack.
        g.goto done_label
      else_label.set!
        # Use the right operand as our result value.
        g.pop # remove the lhs
        @rhs.bytecode(g)
      done_label.set!
    end
  end
  
  class OrComp < LogicalOp
    def initialize (*args)
      @stop_on_false = false
      super
    end
  end
  
  class AndComp < LogicalOp
    def initialize (*args)
      @stop_on_false = true
      super
    end
  end
end
