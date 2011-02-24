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
        g.set_variable
        g.pop
      end
    end
    
    def sexp
      fields = []
      @fields.each {|field| fields << [:pair, field[0].sexp, field[1].sexp]}
      [:table, *fields]
    end
  end
end
