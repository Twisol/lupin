module Lupin::AST
  class Literal
    attr_reader :value
    
    def initialize (val)
      @value = val
    end
    
    def sexp
      @value
    end
  end
  
  class String < Literal
    def bytecode (g)
      g.push_string value
    end
  end
  
  class Number < Literal
    def bytecode (g)
      g.push_number value.to_f
    end
  end
  
  class Boolean < Literal
    def bytecode (g)
      g.push_bool value
    end
  end
  True = Boolean.new(true)
  False = Boolean.new(false)
  
  Nil = Literal.new(nil)
  def Nil.bytecode (g)
    g.push_nil
  end
end
