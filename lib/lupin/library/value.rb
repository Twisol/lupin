module Lupin::Library
  # Base class for all Lua values
  class Value
    attr_reader :value
    
    def initialize (value)
      @value = value
    end
    
    def inspect
      to_s
    end
    
    def to_s
      @value.to_s
    end
    
    def to_bool
      @value ? true : false
    end
    
    def math_op (sym, other)
      raise "Metatables not implemented yet"
    end
    
    def == (other)
      Boolean.new(self.is_a?(other.class) && @value == other.value)
    end
    # alias :"@-" :unm
  end
  
  class Number < Value
    def self.math_op (sym)
      define_method(sym) do |other|
        math_op(sym, other)
      end
    end
    
    math_op(:+)
    math_op(:-)
    math_op(:*)
    math_op(:/)
    math_op(:%)
    math_op(:**)
    math_op(:"@-")
    
  private
    def math_op (sym, other)
      other = other.to_number if other.is_a? String
      
      if other.is_a? Number
        @value.send(sym, other.value)
      else
        super(sym, other)
      end
    end
  end
  
  class String < Value
    def to_number
      m = Lupin::Parser.parse(@value, :root => :number)
      return Nil unless m.to_s == @value
      Lupin::Compiler.compile(m.value).invoke
    end
  end
  
  class Function < Value
    def invoke (args)
      @value.call
    end
  end
  
  class Table < Value
  end
  
  class Userdata < Value
  end
  
  class Thread < Value
  end
  
  class Boolean < Value
    True = new(true)
    False = new(false)
    
    def self.new (value)
      value ? @True : @False
    end
  end
  
  class NilClass < Value
    Nil = new(nil)
    
    def self.new
      Nil
    end
  end
  
  Nil = NilClass::Nil
  True = Boolean::True
  False = Boolean::False
end
