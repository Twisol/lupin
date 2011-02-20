require "citrus"
require "lupin/ast"

module Lupin::Parser
  require "lupin/parser/actions"
  
  Citrus.load(File.join(File.dirname(__FILE__), 'parser', 'parser'))
  
  # Transform a chunk of Lua code into an AST.
  def self.parse (subject, opts={}, *args, &blk)
    Lua.parse(subject, {:consume => true}.merge(opts), *args, &blk).value
  end
end
