module Lupin::AST
  class Literal
    attr_reader :value
    
    def initialize (val)
      @value = val
    end
    
    def bytecode (g)
      g.push_literal Lupin::Value.new(@value)
    end
    
    def sexp
      @value
    end
  end
end
