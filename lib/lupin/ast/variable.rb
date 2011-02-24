module Lupin::AST
  class Variable
    def initialize (parent, identifier)
      @parent = parent
      @name = identifier
    end
    
    def bytecode (g)
      push_parent(g)
      @name.bytecode(g)
      g.get_variable
    end
    
    def set_value (g)
      push_parent(g)
      swap_stack
      
      @name.bytecode(g)
      swap_stack
      
      g.set_variable
    end
    
    def sexp
      [:variable, @parent ? @parent.sexp : nil, @name.sexp]
    end
  
  protected
    def push_parent(g)
      if @parent == nil
        g.push_environment
      else
        @parent.bytecode(g)
      end
    end
  end
end
