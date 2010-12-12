module Lupin
  class State
    def compile (ast)
      g = Generator.new(self)
      
      # ast.bytecode(g)
      g.push_true
      g.ret
      
      Code.new(g.assemble(:call, "dynamic", 1))
    end
  end
  
  class Code
    attr_reader :cm
    
    def initialize (cm)
      @cm = cm
      Rubinius.add_method :call, cm, Rubinius::object_metaclass(self), :public
    end
    
    def decode
      @cm.decode
    end
  end
  
  class Generator
    def initialize (lstate)
      @state, @g = lstate, Rubinius::Generator.new
    end
    
    def push_literal (arg)
      g.push_literal(arg)
    end
    
    def push_true
      g.push_true
    end
    
    def push_false
      g.push_false
    end
    
    def push_nil
      g.push_nil
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
  end
end
