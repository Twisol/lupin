module Lupin::AST
  class Call
    def initialize (func, args)
      @func, @args = func, args
    end
    
    def bytecode (g)
      @func.bytecode(g)
      @args.each {|arg| arg.bytecode(g)}
      g.call(@args.count)
    end
    
    def sexp
      [:call, @func.sexp, @args.map {|arg| arg.sexp}]
    end
  end
end
