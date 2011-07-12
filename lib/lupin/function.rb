class Lupin::Code
  def initialize (cm)
    Rubinius.add_method :call, cm, (class << self; self; end), :public
    @cm = cm
  end
  
  # Replaced by the compiled method
  def call
    raise "This shouldn't be reached!"
  end
  
  def decode
    @cm.decode
  end
end

class Lupin::Function
  attr_accessor :name, :first_line, :last_line, :upvalue_count,
                :parameter_count, :is_vararg, :maxstack, :instructions,
                :constants, :functions, :lines, :locals, :upvalues
  
  def initialize (state)
    @state = state
  end
  
  def compile
    g = Lupin::Generator.new(@state, self)
    
    pp instructions
    instructions.each do |op|
      g.pre_instruction
      op.compile(g)
    end
    
    g.assemble("hi", "lolwat")
  end
end
