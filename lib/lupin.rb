module Lupin
  require "lupin/version"
  
  require "lupin/ast"
  require "lupin/parser"
  require "lupin/compiler"
  
  def self.eval (str)
    ast = Lupin::Parser.parse(str, :root => :expression).value
    Lupin::Compiler.compile(ast).execute
  end
end
