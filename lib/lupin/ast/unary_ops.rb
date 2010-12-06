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
    
    def sexp
      [:"-@", @operand.sexp]
    end
  end
  
  class Negation < UnaryOp
    def bytecode (g)
      done_label = g.new_label
      else_label = g.new_label
      
      @operand.bytecode(g)
      g.send :to_bool, 0
      
      g.gif else_label
        g.push_literal Lupin::Library::False
        g.goto done_label
      else_label.set!
        g.push_literal Lupin::Library::True
      done_label.set!
    end
    
    def sexp
      [:not, @operand.sexp]
    end
  end
  
  Length = Class.new(UnaryOp)
end
