#!/usr/bin/env ruby
require "rubygems"
gem "bundler"
require "bundler"

Bundler.setup
require "lupin"

# Extremely basic, stupid-simple REPL.
lua = Lupin::State.new
lua.globals['exit'] = Kernel.method(:exit)

loop do
  print '> '
  begin
    expr = gets
    break unless expr
    puts "=> #{Lupin.eval(lua, expr.chomp)}"
  rescue => ex
    ex.render
  end
end

puts ""
