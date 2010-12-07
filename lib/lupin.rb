module Lupin
  require "lupin/version"
  
  require "lupin/types"
  require "lupin/compiler"
  require "lupin/ast"
  require "lupin/parser"
  
  def self.eval (str)
    ast = Lupin::Parser.parse(str, :root => :expression).value
    Lupin::Compiler.compile(ast).execute
  end
end
