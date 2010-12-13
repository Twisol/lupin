module Lupin::AST
  class Literal
    attr_reader :value
    
    def initialize (val)
      @value = val
    end
    
    def bytecode (g)
      g.push_literal @value
    end
    
    def sexp
      @value
    end
  end
end
