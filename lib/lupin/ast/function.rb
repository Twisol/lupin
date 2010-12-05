module Lupin::AST
  class FunctionCall
    def initialize (func, args)
      @func, @args = func, args
    end
    
    def sexp
      [:call, @func.sexp, args.map {|arg| arg.sexp}]
    end
  end
end
