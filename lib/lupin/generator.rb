require 'lupin/value'

module Lupin
  class Generator
    def initialize (lstate)
      @state, @g = lstate, Rubinius::Generator.new
    end
    
    def push_literal (arg)
      g.push_literal(arg)
    end
    
    def add
      math :+, '__add'
    end
    
    def sub
      math :-, '__sub'
    end
    
    def mul
      math :*, '__mul'
    end
    
    def div
      math :/, '__div'
    end
    
    def mod
      math :%, '__mod'
    end
    
    def pow
      math :**, '__pow'
    end
    
    def concat
      g.pop_many 2
      g.push_literal "Hello from the unfinished concatenation routine"
    end
    
    def ret
      g.ret
    end
    
    def assemble (name, file, line)
      g.name = name.to_sym
      g.file = file.to_sym
      g.set_line(line.to_i)
      
      g.close
      g.encode
      g.package Rubinius::CompiledMethod
    end
    
    attr_reader :g, :state
    private :g
    
  private
    # Perform arithmetic on two operands, coercing them to numbers if possible.
    # If one of the operands is not number-like, try to invoke a metamethod.
    def math (op, metamethod)
      else_label = g.new_label
      else2_label = g.new_label
      done_label = g.new_label
      
      # lhs, rhs
      g.send :try_tonumber, 0
      g.dup                    # lhs, rhs, rhs
      g.send :type, 0          # lhs, rhs, type
      g.push_literal :number   # lhs, rhs, type, :number
      g.send :==, 1            # lhs, rhs, (is-number?)
      g.gif else_label
        # lhs, rhs
        g.rotate 2               # rhs, lhs
        g.send :try_tonumber, 0
        g.dup                    # rhs, lhs, lhs
        g.send :type, 0          # rhs, lhs, type
        g.push_literal :number   # rhs, lhs, type, :number
        g.send :==, 1            # rhs, lhs, (is-number?)
        g.gif else2_label
          # rhs, lhs
          g.rotate 2           # lhs, rhs
          g.send op, 1         # sum
          g.goto done_label
        else2_label.set!
          g.rotate 2           # lhs, rhs
        # Fall through to the outer else clause
      else_label.set!
        # lhs, rhs
        # Code will go here for metatables. If the metamethod doesn't exist,
        # raise an error.
        g.pop_many 2
        g.push_self
        g.push_literal "Cannot call #{metamethod}: Metatables aren't implemented yet."
        g.send :raise, 1, true
      done_label.set!
      # result
    end
    
    # Used intermittently for debugging. Equivalent to p(arg)
    def puts_top
      g.dup
      g.push_self
      g.rotate 2
      g.send :p, 1, true
      g.pop
    end
  end
end
