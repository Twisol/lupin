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
  
  class UnaryMinus < UnaryOp
    def bytecode (g)
      # TODO: Implement lookup for __unm in @operand's metatable
      @operand.bytecode(g)
      g.send :"-@", 0
    end
  end
  
  class Negation < UnaryOp
    def bytecode (g)
      @operand.bytecode(g)
      g.send :"to_bool", 0
      
      g.push_false
      g.send :"==", 1
    end
  end
end
