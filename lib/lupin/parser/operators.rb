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
end
