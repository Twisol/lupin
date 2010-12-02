module Lupin::AST
  class UnaryOp
    attr_reader :operand
    
    def initialize (operand)
      @operand = operand
    end
    
    def == (other)
      self.class == other.class &&
      self.operand = other.operand
    end
  end
  
  UnaryMinus = Class.new(UnaryOp)
  NegationS = Class.new(UnaryOp)
end
