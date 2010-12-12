module Lupin
  require "lupin/version"
  require "lupin/parser"
  require "lupin/state"
  
  def self.eval (state, str)
    ast = Lupin::Parser.parse(str, :root => :expression)
    state.compile(ast).call
  end
end
