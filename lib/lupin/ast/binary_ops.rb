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
  end
  
  Addition = Class.new(BinaryOp)
  Subtraction = Class.new(BinaryOp)
  Multiplication = Class.new(BinaryOp)
  Division = Class.new(BinaryOp)
end
