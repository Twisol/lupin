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
      try_tonumber
      g.dup                    # lhs, rhs, rhs
      g.push_const :Numeric    # lhs, rhs, rhs, Numeric
      g.send :is_a?, 1         # lhs, rhs, (is-numeric?)
      g.gif else_label
        # lhs, rhs
        g.rotate 2             # rhs, lhs
        try_tonumber
        g.dup                  # rhs, lhs, lhs
        g.push_const :Numeric  # rhs, lhs, lhs, Numeric
        g.send :is_a?, 1       # rhs, lhs, (is-numeric?)
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
    
    # If the top value is a String, convert it to a float.
    # Otherwise, leave it as-is.
    # (arg.is_a?(String) ? (Float(arg) rescue arg) : arg)
    def try_tonumber
      # data
      done_label = g.new_label
      rescue_label = g.new_label
      
      # Bail out early if it's not a string
      g.dup                   # data, data
      g.push_const(:String)   # data, data, String
      g.send :is_a?, 1        # data, (is-string?)
      g.gif done_label        # data
      
      g.push_exception_state  # data, ex_state
      g.rotate 2              # ex_state, data
      g.setup_unwind rescue_label, 0
        g.dup                   # data, data
        g.push_const :Lupin     # data, data, Lupin
        g.find_const :Parser    # data, data, Lupin::Parser
        g.rotate 2              # data, Lupin::Parser, data
        
        # {:root => :number}
        g.push_const :Hash
        g.push_literal 2
        g.send :new_from_literal, 1
        g.dup
        g.push_literal :root
        g.push_literal :number
        g.send :[]=, 2
        g.pop
        # data, Lupin::Parser, data, opts
        
        g.send :parse, 2        # data, ast
        g.send :value, 0        # data, result
        g.rotate 2              # result, data
        g.pop                   # result
      g.pop_unwind
      rescue_label.set!
      g.rotate 2              # result, ex_state
      g.restore_exception_state
      
      done_label.set!
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
