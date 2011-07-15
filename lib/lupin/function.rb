# Represents the Lua function prototype that backs a function instance.
class Lupin::Prototype
  attr_accessor :name, :first_line, :last_line, :upvalue_count,
                :parameter_count, :is_vararg, :maxstack, :instructions,
                :constants, :prototypes, :lines, :locals, :upvalues
  
  def initialize (state)
    @state = state
    @cm = nil
  end
  
  def compile
    g = Lupin::Generator.new(@state, self)
    instructions.compile(g)
    
    # TODO: use useful names
    @cm = g.assemble("hi", "lolwat")
  end
  
  def attach (sym, target)
    compile unless @cm
    Rubinius.add_method sym, @cm, target, :public
  end
  
  def decode
    @cm.decode if @cm
  end
  
  def cm
    @cm
  end
end

class Lupin::Function
  attr_accessor :upvalues
  
  def initialize (proto)
    proto.attach :call, (class << self; self; end)
    @proto = proto
    @upvalues = []
  end
  
  # Replaced by the compiled method
  def call
    raise "This shouldn't be reached!"
  end
  
  def decode
    @proto.decode
  end
end
