module Lupin
  require "lupin/version"
  
  require "lupin/ast"
  require "lupin/parser"
  require "lupin/compiler"
  
  def self.eval (str)
    ast = Lupin::Parser.parse(str, :root => :expression).value
    m = Module.new
    (class << m; self; end).dynamic_method :x do |g|
      Lupin::Compiler.compile(ast, g)
      g.ret
    end
    m.x
  end
end
