module Lupin::AST
  class Table
    def initialize (fieldlist=[])
      current_integer = 0
      fieldlist.each do |a|
        a[0] ||= Lupin::AST::Number.new(current_integer += 1)
      end
      @fields = fieldlist
    end
    
    def bytecode (g)
      g.push_table
      
      @fields.each do |k, v|
        g.dup_top
        k.bytecode(g)
        v.bytecode(g)
        g.set_table
        g.pop
      end
    end
    
    def sexp
      fields = []
      @fields.each {|field| fields << [:pair, field[0].sexp, field[1].sexp]}
      [:table, *fields]
    end
  end
  
  class TableGet
    def initialize (tbl, key)
      @tbl = tbl
      @key = key
    end
    
    def bytecode (g)
      @tbl.bytecode(g)
      @key.bytecode(g)
      g.get_table
    end
    
    def sexp
      [:[], @tbl.sexp, @key.sexp]
    end
  end
end
