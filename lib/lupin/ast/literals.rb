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
      g.push_literal Lupin::Types::String.new(@value)
    end
  end
  
  class Number < Literal
    def initialize (base, exponent=0)
      super(base.to_f * 10 ** exponent)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Types::Number.new(@value)
    end
  end
  
  class True < Literal
    def initialize
      super(true)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Types::True
    end
  end
  
  class False < Literal
    def initialize
      super(false)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Types::False
    end
  end
  
  class Nil < Literal
    def initialize
      super(nil)
    end
    
    def bytecode (g)
      g.push_literal Lupin::Types::Nil
    end
  end
end
