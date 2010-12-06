module Lupin
  require "lupin/version"
  
  require "lupin/ast"
  require "lupin/parser"
  require "lupin/compiler"
  require "lupin/library"
  
  def self.eval (str)
    ast = Lupin::Parser.parse(str, :root => :expression, :consume => true).value
    Lupin::Compiler.compile(ast).execute
  end
end
