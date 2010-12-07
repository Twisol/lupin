module Lupin::AST
  class BinaryOp
    attr_reader :lhs, :rhs
    
    def initialize (lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end
    
    def == (other)
      self.class == other.class &&
      self.lhs == other.lhs &&
      self.rhs == other.rhs
    end
    
    def self.for (sym)
      Class.new(self) do
        define_method :bytecode do |g|
          @lhs.bytecode(g)
          @rhs.bytecode(g)
          g.send sym, 1
        end
        
        define_method :sexp do
          [sym, @lhs.sexp, @rhs.sexp]
        end
      end
    end
  end
  
  Addition       = BinaryOp.for :+
  Subtraction    = BinaryOp.for :-
  Multiplication = BinaryOp.for :*
  Division       = BinaryOp.for :/
  Modulo         = BinaryOp.for :%
  Power          = BinaryOp.for :**
  
  
  class OrComp < BinaryOp
    def bytecode (g)
      done_label = g.new_label
      else_label = g.new_label
      
      @lhs.bytecode(g)
      
      # Duplicate the left operand so we branch based on it.
      g.dup
      g.send :to_bool, 0
      
      # (lhs ? lhs : rhs)
      g.gif else_label
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
  
  class AndComp < BinaryOp
    def bytecode (g)
      done_label = g.new_label
      else_label = g.new_label
      
      @lhs.bytecode(g)
      
      # Duplicate the left operand so we branch based on it.
      g.dup
      g.send :to_bool, 0
      
      # (lhs ? rhs : lhs)
      g.git else_label
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
  
  LessThan = Class.new(BinaryOp)
  GreaterThan = Class.new(BinaryOp)
  AtMost = Class.new(BinaryOp)
  AtLeast = Class.new(BinaryOp)
  NotEqual = Class.new(BinaryOp)
  Equal = Class.new(BinaryOp)
  
  Concatenate = Class.new(BinaryOp)
end
