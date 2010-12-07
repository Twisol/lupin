require "citrus"

module Lupin::Parser
  require "lupin/parser/actions"
  
  Citrus.load(File.join(File.dirname(__FILE__), 'parser', 'parser'))
  
  def self.parse (subject, opts={}, *args, &blk)
    Lua.parse(subject, {:consume => true}.merge(opts), *args, &blk)
  end
end
