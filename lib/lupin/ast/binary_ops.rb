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
  Power = Class.new(BinaryOp)
  
  OrComp = Class.new(BinaryOp)
  AndComp = Class.new(BinaryOp)
  
  LessThan = Class.new(BinaryOp)
  GreaterThan = Class.new(BinaryOp)
  AtMost = Class.new(BinaryOp)
  AtLeast = Class.new(BinaryOp)
  NotEqual = Class.new(BinaryOp)
  Equal = Class.new(BinaryOp)
  
  Concatenate = Class.new(BinaryOp)
end
