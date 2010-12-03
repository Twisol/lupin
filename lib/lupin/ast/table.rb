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
  
  class TableGet
    def initialize (tbl, key)
      @tbl, @key = tbl, key
    end
  end
end
