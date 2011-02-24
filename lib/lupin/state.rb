require 'lupin/generator'

module Lupin
  class State
    attr_reader :metatables 
    
    def initialize
      @env = Lupin::Types::Table.new
    end
    
    def compile (ast)
      g = Generator.new(self)
      
      ast.bytecode(g)
      g.ret
      
      Code.new(g.assemble("<eval>", :dynamic, 1))
    end
    
    def globals
      @env
    end
  end
  
  class Code
    def initialize (cm)
      Rubinius.add_method :call, cm, Rubinius.object_metaclass(self), :public
      @cm = cm
    end
    
    # Execute the compiled method
    def call
      # No-op until redefined
    end
    
    def decode
      @cm.decode
    end
  end
end
