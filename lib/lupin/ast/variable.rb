module Lupin::AST
  class Variable
    def initialize (identifier)
      @name = identifier
    end
    
    def bytecode (g)
      g.push_environment
      @name.bytecode(g)
      g.table_get
    end
    
    def sexp
      [:variable, @name.sexp]
    end
  end
  
  class Indexer
    def initialize (container, key)
      @container = container
      @key = key
    end
    
    def bytecode (g)
      @container.bytecode(g)
      @key.bytecode(g)
      g.table_get
    end
    
    def sexp
      [:[], @container.sexp, @key.sexp]
    end
  end
end
