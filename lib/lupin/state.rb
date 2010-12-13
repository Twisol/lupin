require 'lupin/generator'

module Lupin
  class State
    def compile (ast)
      g = Generator.new(self)
      
      ast.bytecode(g)
      g.ret
      
      Code.new(g.assemble("<eval>", :dynamic, 1))
    end
  end
  
  class Code
    attr_reader :cm
    
    def initialize (cm)
      @cm = cm
      Rubinius.add_method :call, cm, Rubinius.object_metaclass(self), :public
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
