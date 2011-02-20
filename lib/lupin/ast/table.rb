module Lupin::AST
  class Table
    def initialize (fieldlist=[])
      @fields = {}
      current_integer = 0
      fieldlist.each do |k, v|
        k ||= Lupin::AST::Literal.new(current_integer += 1)
        @fields[k] = v
      end
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
      @tbl, @key = tbl, key
    end
  end
end
