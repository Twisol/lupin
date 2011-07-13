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
    
    instructions.each do |op|
      g.pre_instruction
      op.compile(g)
    end
    
    # TODO: use useful names
    @cm = g.assemble("hi", "lolwat")
  end
  
  def attach (target)
    compile unless @cm
    Rubinius.add_method :call, @cm, target, :public
    target
  end
  
  def decode
    @cm.decode if @cm
  end
  
  def cm
    @cm
  end
end

class Lupin::Function
  def initialize (code)
    code.attach(class << self; self; end)
    @code = code
  end
  
  # Replaced by the compiled method
  def call
    raise "This shouldn't be reached!"
  end
  
  def decode
    @code.decode
  end
end
