#!/usr/bin/env ruby

require "rubygems"
gem "bundler"
require "bundler"
Bundler.load

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "lupin"

# Eventually, a REPL will probably go here.
