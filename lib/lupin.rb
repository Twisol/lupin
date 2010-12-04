module Lupin
  require "lupin/version"
  
  require "lupin/ast"
  require "lupin/parser"
  require "lupin/compiler"
  
  def self.eval (str)
    o = Object.new
    Rubinius.object_metaclass(o).dynamic_method :call do |g|
      ast = Lupin::Parser.parse(str, :root => :expression).value
      Lupin::Compiler.compile(ast, g)
      g.ret
    end
    o.call
  end
end
