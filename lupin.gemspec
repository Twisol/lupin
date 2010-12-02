# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'lupin/version'

Gem::Specification.new do |s|
  s.name = 'lupin'
  s.version = Lupin::VERSION
  s.license = 'MIT'
  s.author = 'Jonathan Castello'
  s.email = 'jonathan@jonathan.com'
  
  s.summary = 'An implementation of Lua for the Rubinius VM/'
  s.description = 'An implementation of Lua for the Rubinius VM/'
  
  s.files = Dir['lib/**/*'].reject {|f| f =~ /\.rbc$/}
  
  s.add_dependency 'citrus', '~> 2.2.0'
  s.add_development_dependency 'rspec', '~> 2.2.0'
  s.add_development_dependency 'bundler', '~> 1.0.0'
end
