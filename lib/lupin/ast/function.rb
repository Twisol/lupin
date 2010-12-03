module Lupin::AST
  class FunctionCall
    def initialize (func, args)
      @func, @args = func, args
    end
  end
end
