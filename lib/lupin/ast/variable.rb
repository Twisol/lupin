module Lupin::AST
  class Variable
    def initialize (identifier)
      @name = identifier
    end
    
    def bytecode (g)
      # TODO: Add variable lookup.
      g.push_nil
    end
    
    def sexp
      [:variable, @name.sexp]
    end
  end
end
