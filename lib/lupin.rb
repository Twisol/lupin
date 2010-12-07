module Lupin
  require "lupin/version"
  
  require "lupin/ast"
  require "lupin/parser"
  require "lupin/compiler"
  require "lupin/types"
  
  def self.eval (str)
    ast = Lupin::Parser.parse(str, :root => :expression).value
    Lupin::Compiler.compile(ast).execute
  end
end
