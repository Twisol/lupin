module Lupin
  class Generator
    attr_reader :g, :state
    private :g
    
    def initialize (lstate)
      @state = lstate
      @g = Rubinius::Generator.new
      @env = Lupin::Types::Table.new(@state)
    end
    
    def push_number (num)
      g.push_literal Lupin::Types::Number.new(num)
    end
    
    def push_string (str)
      g.push_literal Lupin::Types::String.new(str)
    end
    
    def push_table
      g.push_literal Lupin::Types::Table.new(@state)
    end
    
    def push_bool (bool)
      g.push_literal Lupin::Types::Boolean.new(bool)
    end
    
    def push_nil
      g.push_literal Lupin::Types::Nil
    end
    
    def dup_top
      g.dup
    end
    
    def pop
      g.pop
    end
    
    def ret
      g.ret
    end
    
    def add
      g.send :+, 1
    end
    
    def sub
      g.send :-, 1
    end
    
    def mul
      g.send :*, 1
    end
    
    def div
      g.send :/, 1
    end
    
    def mod
      g.send :%, 1
    end
    
    def pow
      g.send :**, 1
    end
    
    def lt
      g.send :<, 1
    end
    
    def le
      g.send :<=, 1
    end
    
    def eq
      g.send :==, 1
    end
    
    def ge
      g.send :>=, 1
    end
    
    def gt
      g.send :>, 1
    end
    
    def neq
      eq
      push_bool false
      eq
    end
    
    def get_table
      g.send :[], 1
    end
    
    def set_table
      g.send :[]=, 2
    end
    
    def concat
      g.pop_many 2
      g.push_literal "Hello from the unfinished concatenation routine"
    end
    
    def assemble (name, file, line)
      g.name = name.to_sym
      g.file = file.to_sym
      g.set_line(line.to_i)
      
      g.close
      g.encode
      g.package Rubinius::CompiledMethod
    end
    
  private
    # Used intermittently for debugging. Equivalent to p(arg)
    def puts_top
      g.dup
      g.push_self
      g.swap
      g.send :p, 1, true
      g.pop
    end
  end
end
