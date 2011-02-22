module Lupin
  require "lupin/version"
  require "lupin/parser"
  require "lupin/state"
  
  # Evaluate a string as a chunk of Lua code.
  # CAVEAT: Really only works for expressions right now.
  def self.eval (state, str)
    ast = Lupin::Parser.parse(str, :root => :expression)
    state.compile(ast).call
  end
  
  def self.sexp (state, str)
    Lupin::Parser.parse(str, :root => :expression).sexp
  end
  
  def self.bytecode (state, str)
    ast = Lupin::Parser.parse(str, :root => :expression)
    state.compile(ast).decode
  end
end
