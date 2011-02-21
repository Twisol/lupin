require 'lupin/generator'

module Lupin
  class State
    attr_reader :metatables 
    
    def initialize
      @metatables = {}
    end
    
    def compile (ast)
      g = Generator.new(self)
      
      ast.bytecode(g)
      g.ret
      
      Code.new(g.assemble("<eval>", :dynamic, 1))
    end
    
    def getmetamethod (obj, name)
      case obj
      when Lupin::Types::Table, Lupin::Types::Userdatum
        mt = @metatables[obj]
      else
        mt = @metatables[obj.class]
      end
      
      mt && mt[name]
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
