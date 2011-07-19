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
    
    # Shift the parameters into place.
    if function.parameter_count > 0
      push_parameters
      # This mutates the params array, but that's okay: the leftovers are used
      # in the VARARGS instruction.
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
  
  def if_else (proc_then=nil, proc_else=nil)
    else_label = @g.new_label
    done_label = @g.new_label
    
    if proc_then
      @g.goto_if_false else_label
        proc_then.call
      @g.goto done_label
      else_label.set!
        proc_else.call if proc_else
      done_label.set!
    elsif proc_else
      @g.goto_if_true done_label
        proc_else.call
      done_label.set!
    end
  end
  
  
  def pop
    @g.pop
  end
  
  def move_down (num)
    @g.move_down num
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
    if register & 256 == 256
      push_constant register & ~256
    else
      local_get register
    end
  end
  
  def local_get (register)
    @g.push_local register+1
    @g.send :value, 0 if @upvalue_locals[register]
  end
  
  def local_set (register)
    if @upvalue_locals[register]
      @g.push_local register+1
      move_down 1
      @g.send :value=, 1
    else
      @g.set_local register+1
    end
  end
  
  def range_get (base, count)
    if count >= 0
      count.times do |i|
        local_get base+i
      end
      @g.make_array count
    else
      local_get base
    end
  end
  
  def range_set (base, count)
    if count >= 0
      count.times do |i|
        @g.shift_array
        local_set base+i
        pop
      end
    else
      local_set base
    end
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
  end
  
  def table_get
    call_primitive :index, 2
  end
  
  def table_set
    call_primitive :newindex, 3
  end
  
  def global_get
    call_primitive :get_global, 1
  end
  
  def global_set
    call_primitive :set_global, 2
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
  
  def eq
    call_primitive :eq, 2
  end
  
  def lt
    call_primitive :lt, 2
  end
  
  def le
    call_primitive :le, 2
  end
  
  def concat
    call_primitive :concat, 1
  end
  
  def len
    call_primitive :len, 1
  end
  
  def call
    call_primitive :call, 2
  end
  
  def return
    @g.ret
  end
  
  def vararg (base, count)
    push_parameters
    @g.send :dup, 0
    range_set(base, count)
    pop
  end
  
  def new_table (array_size, hash_size)
    @g.push_literal Hash
    @g.send :new, 0
  end
  
  def new_closure (index)
    proto = @prototypes[index]
    @g.push_literal Lupin::Function
    @g.push_literal proto
    @g.send :new, 1
  end
  
  def share_upvalue (index)
    @g.dup_top
    @g.send :upvalues, 0
    
    upvalue_get index
    @g.send :<<, 1
    pop
  end
  
  def share_local (local)
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
      pop
    end
    
    @g.send :<<, 1
    pop
    
    @upvalue_locals[local] = true
  end
  
  def unshare (base)
    locals = []
    @upvalue_locals.each_key {|i| locals << i if i >= base}
    
    locals.each do |i|
      @upvalue_locals.delete(i)
      push_nil
      local_set i
      pop
    end
  end
  
protected
  def call_primitive (sym, params)
    @g.push_literal @state
    @g.move_down params
    @g.send sym, params
  end
  
  def push_parameters
    @g.push_local 0
  end
end
