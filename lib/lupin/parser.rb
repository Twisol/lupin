require "citrus"

module Lupin::Parser
  require "lupin/parser/actions"
  
  Citrus.load(File.join(File.dirname(__FILE__), 'parser', 'parser'))
  
  def self.parse (*args, &blk)
    Lua.parse(*args, &blk)
  end
end
