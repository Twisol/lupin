module Lupin::Types
  class String < Value
    def to_number
      m = Lupin::Parser.parse(@value, :root => :number)
      return Nil unless m.to_s == @value
      Lupin::Compiler.compile(m.value).invoke
    end
    
    def == (other)
      if other.is_a? String
        Boolean.new(@value == other.value)
      else
        super
      end

    end
    
    def <= (other)
      if other.is_a? String
        Boolean.new(@value <= other.value)
      else
        super
      end
    end
    
    def < (other)
      if other.is_a? String
        Boolean.new(@value < other.value)
      else
        super
      end
    end
    
    def concatenate (other)
      other = String.new(other.to_s) if other.is_a? Number
      
      case other
      when String
        String.new("#{@value}#{other.value}")
      else
        super
      end
    end
  end
end
