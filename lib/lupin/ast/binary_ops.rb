module Lupin::AST
  # Base class for all binary operations.
  class BinaryOp
    def initialize (lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end
    
    # Helper method for defining binary operations
    def self.for (sym, op)
      # Create a sublass of BinaryOp
      klass = Class.new(self) do
        def bytecode (g)
          @lhs.bytecode(g)
          @rhs.bytecode(g)
          g.send self.class::OP
        end
        
        def sexp
          [self.class::SEXP, @lhs.sexp, @rhs.sexp]
        end
      end
      
      # Store the symbols as constants on the new class.
      klass.const_set :OP, op
      klass.const_set :SEXP, sym
      klass
    end
  end
  
  
  ###
  # Simple operations
  ###
  Addition       = BinaryOp.for :+,    :add
  Subtraction    = BinaryOp.for :-,    :sub
  Multiplication = BinaryOp.for :*,    :mul
  Division       = BinaryOp.for :/,    :div
  Modulo         = BinaryOp.for :%,    :mod
  Power          = BinaryOp.for :**,   :pow
  Concatenate    = BinaryOp.for :"..", :concat
  
  ###
  # Relational operations
  ###
  Equal    = BinaryOp.for :==,   :eq
  NotEqual = BinaryOp.for :'!=', :neq
  AtMost   = BinaryOp.for :<=,   :le
  AtLeast  = BinaryOp.for :>=,   :ge
  LessThan = BinaryOp.for :<,    :lt
  MoreThan = BinaryOp.for :>,    :gt
  
  
  
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
