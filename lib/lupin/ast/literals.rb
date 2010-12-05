module Lupin::AST
  class Literal
    attr_reader :value
    
    def initialize (val)
      @value = val
    end
    
    def == (literal)
      @value == literal
    end
    
    def sexp
      @value
    end
  end
  
  class String < Literal
    def initialize (str)
      super(str)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Library::String.new(@value)
    end
  end
  
  class Number < Literal
    def initialize (base, exponent=0)
      super(base.to_f * 10 ** exponent)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Library::Number.new(@value)
    end
  end
  
  class True < Literal
    def initialize
      super(true)
    end
  end
  
  class False < Literal
    def initialize
      super(false)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Library::False
    end
  end
  
  class Nil < Literal
    def initialize
      super(nil)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Library::Nil
    end
  end
end
