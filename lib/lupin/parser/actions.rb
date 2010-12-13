module Lupin::Parser
  module LeftAssoc
    def value
      expr = lhs.value
      list.matches.each do |m|
        expr = m.op.value.new(expr, m.rhs.value)
      end
      
      expr
    end
  end
  
  module RightAssoc
    def value
      expr = rhs.value
      list.matches.reverse_each do |m|
        expr = m.op.value.new(m.lhs.value, expr)
      end
      
      expr
    end
  end
  
  module Unary
    def value
      expr = rhs.value
      list.matches.reverse_each do |m|
        expr = m.op.value.new(expr)
      end
      
      expr
    end
  end
  
  module List
    def value
      [self].concat(list.matches).map {|m| m.item.value}
    end
  end
  
  module StringLiteral
    def value
      s = str.to_s
      s.gsub! /\\(\d{1,3}|\D)/m do
        seq = $1
        case seq
          when 'a'  then "\a"
          when 'b'  then "\b"
          when 'f'  then "\f"
          when 'n'  then "\n"
          when 'r'  then "\r"
          when 't'  then "\t"
          when 'v'  then "\v"
          when "\r" then "\n"
          when /\d{1,3}/ then seq.to_i.chr
          else seq
        end
      end
      
      Lupin::AST::Literal.new(s)
    end
  end
  
  module LongStringLiteral
    def value
      Lupin::AST::Literal.new(match(/\[(=*)\[\n?(.*?)\]\1\]/m)[2])
    end
  end
  
  module HexLiteral
    def value
      Lupin::AST::Literal.new(to_i(16))
    end
  end
  
  module DecimalLiteral
    def value
      Lupin::AST::Literal.new(base.value * 10 ** (exponent == '' ? 0 : exponent.value))
    end
  end
  
  module TableLiteral
    def value
      Lupin::AST::Table.new(list == '' ? [] : list.value)
    end
  end
  
  module Pair
    def value
      [k == '' ? Lupin::AST::Literal.new(nil) : k.value, v.value]
    end
  end
end
