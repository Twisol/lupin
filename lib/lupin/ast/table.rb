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
    
    def sexp
      fields = []
      @fields.each {|field| fields << [:pair, field[0].sexp, field[1].sexp]}
      [:table, *fields]
    end
  end
  
  class TableGet
    def initialize (tbl, key)
      @tbl, @key = tbl, key
    end
  end
end
