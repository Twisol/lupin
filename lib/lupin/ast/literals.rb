module Lupin::AST
  class Literal
    attr_reader :value
    
    def initialize (val)
      @value = val
    end
    
    def == (literal)
      @value == literal.value
    end
  end
  
  class String < Literal
    def initialize (str)
      str.gsub! /\\(\d{1,3}|\D)/m do
        seq = $1
        case seq
          when 'a'  then "\a"
          when 'b'  then "\b"
          when 'f'  then "\f"
          when 'n'  then "\n"
          when 'r'  then "\r"
          when 't'  then "\t"
          when 'v'  then "\v"
          when "\r" then "\n"
          when /\d{1,3}/ then seq.to_i.chr
          else seq
        end
      end
      
      super(str)
    end
  end
  
  class LongString < Literal
    def initialize (str)
      str = str[1..-1] if str[0,1] == "\n"
      super(str)
    end
  end
  
  class Number < Literal
    def initialize (base, exponent=0)
      super(base.to_f * (10 ** exponent))
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
  end
  
  class Nil < Literal
    def initialize
      super(nil)
    end
  end
end
