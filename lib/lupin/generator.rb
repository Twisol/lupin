class Lupin::Reference
  attr_accessor :value
  
  def initialize (value=nil)
    @value = value
  end
end

class Lupin::Generator
  def initialize (state, function)
    @g = Rubinius::Generator.new
    @state = state
    @constants = function.constants
    @prototypes = function.prototypes
    
    # Goto labels to map jumps from Lua opcode counts to Rubinius counts
    @ips = []
    @current_ip = 0
    
    @upvalue_locals = {} # Track which visible locals are held by closures.
    @upvalue_count = 0 # How many upvalues are left to add to a new closure?
    
    # Shift the parameters into place.
    if function.parameter_count > 0
      # This mutates the params array, but that's okay: the leftovers are used
      # in the VARARGS instruction.
      push_parameters
      (function.parameter_count).times do |i|
        @g.shift_array
        local_set i
      end
      @g.pop
    end
  end
  
  def assemble (name, file)
    @g.name = name.to_sym
    @g.file = file.to_sym
    @g.set_line 0
    @g.splat_index = 0
    
    @g.use_detected
    @g.close
    @g.encode
    @g.package Rubinius::CompiledMethod
  end
  
  # Do stuff before each instruction
  def pre_instruction
    # Set a compile-time label for jumping to this instruction
    label = @ips[@current_ip]
    if !label
      label = @g.new_label
      @ips[@current_ip] = label
    end
    label.set!
    @current_ip += 1
    
    # TODO: Check debughooks here
  end
  
  def call_primitive (sym, params)
    @g.push_literal @state
    @g.move_down params
    @g.send sym, params
  end
  
  
  def pop
    @g.pop
  end
  
  def push_top
    @g.dup_top
  end
  
  def push_nil
    @g.push_nil
  end
  
  def push_bool (b)
    (b) ? @g.push_true : @g.push_false
  end
  
  def push_number (n)
    @g.push_literal n.to_f
  end
  
  def push_constant (register)
    @g.push_literal @constants[register]
  end
  
  def push_rk (register)
    if register & 256 == 1
      push_constant register & ~256
    else
      local_get register
    end
  end
  
  def push_parameters
    @g.push_local 0
  end
  
  def local_get (register)
    @g.push_local register+1
    @g.send :value, 0 if @upvalue_locals[register]
  end
  
  def local_set (register)
    if @upvalue_locals[register]
      @g.push_local register+1
      @g.swap_stack
      @g.send :value=, 1
    else
      @g.set_local register+1
    end
    @g.pop
  end
  
  def upvalue_get (index)
    @g.push_ivar :@upvalues
    @g.push_int index
    @g.send :[], 1
    @g.send :value, 0
  end
  
  def upvalue_set (index)
    @g.push_ivar :@upvalues
    @g.push_int index
    @g.send :[], 1
    @g.swap_stack
    @g.send :value=, 1
    @g.pop
  end
  
  def table_get
    @g.send :[], 1
  end
  
  def table_set
    @g.send :[]=, 2
    @g.pop
  end
  
  def global_get (register)
    push_constant register
    call_primitive :get_global, 1
  end
  
  def global_set (register)
    push_constant register
    @g.swap_stack
    call_primitive :set_global, 2
    @g.pop
  end
  
  def jump (offset, condition=nil)
    index = @current_ip+offset
    label = @ips[index]
    if !label
      label = @g.new_label
      @ips[index] = label
    end
    
    if condition
      @g.goto_if_true label
    elsif condition == false
      @g.goto_if_false label
    else
      @g.goto label
    end
  end
  
  def jump_if_true (offset)
    jump offset, true
  end
  
  def jump_if_false (offset)
    jump offset, false
  end
  
  def add
    call_primitive :add, 2
  end
  
  def sub
    call_primitive :sub, 2
  end
  
  def mul
    call_primitive :mul, 2
  end
  
  def div
    call_primitive :div, 2
  end
  
  def mod
    call_primitive :mod, 2
  end
  
  def pow
    call_primitive :pow, 2
  end
  
  def unm
    call_primitive :unm, 1
  end
  
  def not
    done_label = @g.new_label
    else_label = @g.new_label
    
    @g.gif else_label
      @g.push_bool true
      @g.goto done_label
    else_label.set!
      @g.push_bool false
    done_label.set!
  end
  
  def len
    call_primitive :length, 1
  end
  
  def eq
    call_primitive :eq, 2
  end
  
  def lt
    call_primitive :lt, 2
  end
  
  def le
    call_primitive :le, 2
  end
  
  def concat (count)
    @g.string_build count
  end
  
  
  def call (base, params, returns)
    if params >= 0
      1.upto(params) do |i|
        local_get base+i
      end
      @g.send :call, params
    else
      # It should be in an array here
      local_get base+1
      @g.push_nil
      @g.send_with_splat :call, 0
    end
    
    @g.cast_multi_value
    
    # Store the returns
    if returns >= 0
      returns.times do |i|
        @g.shift_array
        local_set base+i
      end
      @g.pop
    else
      local_set base
    end
  end
  
  def tailcall (base, params, returns)
    # Rubinius doesn't support tailcalls, so this is currently
    # just a call-and-return.
    
    if params >= 0
      1.upto(params) do |i|
        local_get base+i
      end
      @g.send :call, params
    else
      local_get base+1
      @g.push_nil
      @g.send_with_splat :call, 0
    end
    
    @g.cast_multi_value
    @g.ret
  end
  
  def return (base, returns)
    if returns >= 0
      returns.times do |i|
        local_get base+i
      end
      @g.make_array returns
    else
      local_get base
    end
    
    @g.ret
  end
  
  def vararg (base, count)
    push_parameters
    @g.send :dup, 0
    
    if count >= 0
      count.times do |i|
        @g.shift_array
        local_set base+i
      end
      @g.pop
    else
      local_set base
    end
  end
  
  def tforloop (base, count)
    # Call the iterator function
    local_get base
    local_get base+1
    local_get base+2
    @g.send :call, 2
    @g.cast_multi_value
    
    # Assign the return values
    (base+3).upto(base+2+count) do |i|
      @g.shift_array
      local_set i
    end
    @g.pop
    
    # Jump if the first return was true.
    local_get base+3
    @g.dup_top
    @g.push_nil
    @g.send :==, 1
    @g.jump_if_true 1
    
    # Otherwise, set it as the current loop index.
    local_set base+2
  end
  
  def new_table (array_size, hash_size)
    @g.push_literal Hash
    @g.send :new, 0
  end
  
  def new_closure (index)
    proto = @prototypes[index]
    @g.push_literal Lupin::Function
    # Lupin::Function
    @g.push_literal proto
    # Lupin::Function proto
    @g.send :new, 1
    # function
    
    @upvalue_count = proto.upvalue_count
  end
  
  def ref_upval (index)
    return unless closing?
    
    @g.dup_top
    @g.send :upvalues, 0
    
    upvalue_get index
    
    @g.send :<<, 1
    @g.pop
    
    @upvalue_count -= 1
  end
  
  def ref_local (local)
    return unless closing?
    
    @g.dup_top
    @g.send :upvalues, 0
    
    if @upvalue_locals[local]
      local_get local
    else
      @g.push_literal Lupin::Reference
      local_get local
      @g.send :new, 1
      @g.dup_top
      local_set local
    end
    
    @g.send :<<, 1
    @g.pop
    
    @upvalue_count -= 1
    @upvalue_locals[local] = true
  end
  
  def unref_locals (base)
    locals = []
    @upvalue_locals.each_key do |i,_|
      if i >= base
        @g.push_nil
        local_set i
        
        locals << i
      end
    end
    
    locals.each {|i| @upvalue_locals.delete(i)}
  end
  
  
  def closing?
    @upvalue_count > 0
  end
end
