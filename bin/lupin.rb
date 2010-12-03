#!/usr/bin/env ruby
require "rubygems"
gem "bundler"
require "bundler"

Bundler.setup
require "lupin"

# Eventually, a REPL will go here.
require 'pp'
pp Lupin::Parser.parse("(1+2)*3+4", :root => :expression).value
