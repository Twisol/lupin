class Lupin::Generator
  def initialize (state, function)
    @g = Rubinius::Generator.new
    @state = state
    @constants = function.constants
    @prototypes = function.prototypes
    
    @ips = []    
    @current_ip = 0
    
    if function.parameter_count > 0
      # Put the parameters into locals.
      # This mutates the params array, but that's okay: the leftovers are used
      # in the VARARGS instruction.
      push_parameters
      function.parameter_count.times do |i|
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
  
  def push_constant (register)
    @g.push_literal @constants[register]
  end
  
  def push_rk (register)
    if register & 256
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
  end
  
  def local_set (register)
    @g.set_local register+1
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
  
  def jump (offset)
    index = @current_ip+offset
    label = @ips[index]
    if !label
      label = @g.new_label
      @ips[index] = label
    end
    
    @g.goto label
  end
  
  def jump_if_true (offset)
    done_label = @g.new_label
    
    @g.goto_if_true done_label
    jump offset
    done_label.set!
  end
  
  def jump_if_false (offset)
    done_label = @g.new_label
    
    @g.goto_if_false done_label
    jump offset
    done_label.set!
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
  
  def new_closure (index)
    # TODO
  end
end
