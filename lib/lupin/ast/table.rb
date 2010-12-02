module Lupin::AST
  class Table
    def initialize (fieldlist=[])
      @fields = fieldlist
    end
    
    def == (other)
      @fields == other.instance_variable_get(:@fields)
    end
    
    def [] (key)
      @fields[key]
    end
  end
  
  class Field
    attr_reader :key, :val
    
    def initialize (key, val)
      @key, @val = key, val
    end
  end
end
