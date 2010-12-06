#!/usr/bin/env ruby
require "rubygems"
gem "bundler"
require "bundler"

Bundler.setup
require "lupin"

# Extremely basic, stupid-simple REPL.
loop do
  print '> '
  begin
    expr = gets
    break unless expr
    puts "=> #{Lupin.eval(expr.chomp)}"
  rescue => ex
    ex.render
  end
end

puts ""
