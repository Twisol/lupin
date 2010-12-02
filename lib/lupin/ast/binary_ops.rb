module Lupin::AST
  class BinaryOp
    attr_reader :lhs, :rhs
    
    def initialize (lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end
  end
  
  Addition = Class.new(BinaryOp)
  Subtraction = Class.new(BinaryOp)
  Multiplication = Class.new(BinaryOp)
  Division = Class.new(BinaryOp)
end
