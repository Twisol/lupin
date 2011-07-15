#!/usr/bin/env ruby
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), "lib")
require "lupin"
require "pp"

state = Lupin::State.new
state.set_global :print, method(:p)
state.set_global :test, proc {|*args| [1,2,3]}

def funny (*args)
  args.map {|x| x+42}
end
state.set_global :funny, method(:funny)

$L = state

function = state.loadfile("luac.out")
#puts function.decode
puts function.call
