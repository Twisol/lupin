#!/usr/bin/env ruby

module Lupin; end

class Lupin::Instruction
  BIAS = (2**18-1)/2
  
  OPCODES = [
    :MOVE, :LOADK, :LOADBOOL, :LOADNIL, :GETUPVAL, :GETGLOBAL, :GETTABLE,
    :SETGLOBAL, :SETUPVAL, :SETTABLE, :NEWTABLE, :SELF, :ADD, :SUB, :MUL, :DIV,
    :MOD, :POW, :UNM, :NOT, :LEN, :CONCAT, :JMP, :EQ, :LT, :LE, :TEST, :TESTSET,
    :CALL, :TAILCALL, :RETURN, :FORLOOP, :FORPREP, :TFORLOOP, :SETLIST, :CLOSE,
    :CLOSURE, :VARARG,
  ]
  
  def self.[] (opcode)
    const_get(OPCODES[opcode])
  end
  
  def initialize (register_A, register_Bx)
    # Ensure the values are in range
    @A = register_A & (2**8-1)
    @Bx = register_Bx & (2**18-1)
  end
  
  def _A
    @A
  end
  
  def _B
    @Bx >> 9
  end
  
  def _C
    @Bx & (2**9-1)
  end
  
  def _Bx
    @Bx
  end
  
  def _sBx
    @Bx - BIAS
  end
end

class Lupin::Generator
  def initialize (state, function)
    @g = Rubinius::Generator.new
    @state = state
    @constants = function.constants
    
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
end

class Lupin::Instruction::MOVE < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.local_set _A
  end
end

class Lupin::Instruction::LOADNIL < Lupin::Instruction
  def compile (g)
    g.push_nil
  end
end

class Lupin::Instruction::LOADK < Lupin::Instruction
  def compile (g)
    g.push_constant _Bx
    g.local_set _A
  end
end

class Lupin::Instruction::LOADBOOL < Lupin::Instruction
  def compile (g)
    g.push_bool _B > 0
    g.local_set _A
    
    g.jump 1 if _C > 0
  end
end

class Lupin::Instruction::GETGLOBAL < Lupin::Instruction
  def compile (g)
    g.global_get _Bx
    g.local_set _A
  end
end

class Lupin::Instruction::SETGLOBAL < Lupin::Instruction
  def compile (g)
    g.local_get _A
    g.global_set _Bx
  end
end

class Lupin::Instruction::GETTABLE < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.push_rk _C
    g.table_get
    g.local_set _A
  end
end

class Lupin::Instruction::SETTABLE < Lupin::Instruction
  def compile (g)
    g.local_get _A
    g.push_rk _B
    g.push_rk _C
    g.table_set
  end
end

class Lupin::Instruction::ADD < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.add
    g.local_set _A
  end
end

class Lupin::Instruction::SUB < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.sub
    g.local_set _A
  end
end

class Lupin::Instruction::MUL < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.mul
    g.local_set _A
  end
end

class Lupin::Instruction::DIV < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.div
    g.local_set _A
  end
end

class Lupin::Instruction::MOD < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.mod
    g.local_set _A
  end
end

class Lupin::Instruction::POW < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.pow
    g.local_set _A
  end
end

class Lupin::Instruction::UNM < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.unm
    g.local_set _A
  end
end

class Lupin::Instruction::NOT < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.not
    g.local_set _A
  end
end

class Lupin::Instruction::LEN < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.len
    g.local_set _A
  end
end

class Lupin::Instruction::CONCAT < Lupin::Instruction
  def compile (g)
    _B.upto(_C) do |i|
      g.local_get i
    end
    g.concat _C-_B+1
    g.local_set _A
  end
end

class Lupin::Instruction::JMP < Lupin::Instruction
  def compile (g)
    g.jump _sBx
  end
end

class Lupin::Instruction::CALL < Lupin::Instruction
  def compile (g)
    g.local_get _A
    g.call _A, _B-1, _C-1
  end
end

class Lupin::Instruction::RETURN < Lupin::Instruction
  def compile (g)
    g.return _A, _B-1
  end
end

class Lupin::Instruction::TAILCALL < Lupin::Instruction
  def compile (g)
    g.local_get _A
    g.tailcall _A, _B-1, _C-1
  end
end

class Lupin::Instruction::VARARG < Lupin::Instruction
  def compile (g)
    g.vararg _A, _B-1
  end
end

class Lupin::Instruction::SELF < Lupin::Instruction
  def compile (g)
    g.local_get _B
    g.push_top
    g.push_rk _C
    g.table_get
    g.local_set _A+1
    g.local_set _A
  end
end

class Lupin::Instruction::EQ < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.eq
    if _A == 0
      g.jump_if_false 1
    else
      g.jump_if_true 1
    end
  end
end

class Lupin::Instruction::LT < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.lt
    if _A == 0
      g.jump_if_false 1
    else
      g.jump_if_true 1
    end
  end
end

class Lupin::Instruction::LE < Lupin::Instruction
  def compile (g)
    g.push_rk _B
    g.push_rk _C
    g.le
    if _A == 0
      g.jump_if_false 1
    else
      g.jump_if_true 1
    end
  end
end

class Lupin::Instruction::CLOSURE < Lupin::Instruction
  def compile (g)
    g.closure _Bx
    g.local_set _A
  end
end

class Lupin::Instruction::TEST < Lupin::Instruction
  def compile (g)
    g.local_get _A
    
    if _C == 0
      g.jump_if_false 1
    else
      g.jump_if_true 1
    end
  end
end

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

class Lupin::BinaryStream
  def initialize (state, file)
    @state = state
    @file = file
    @next = 0
  end
  
  def read (type)
    case type
    when Numeric
      left = @next
      @next += type
      @file[left...@next]
    when :byte
      read(1).unpack("C")[0]
    when :size_t
      read(4).unpack("L")[0]
    when :number
      read(8).unpack("D")[0]
    when :bool
      read(1).ord == 0
    when :integer
      read(:size_t)
    when :string
      length = read(:size_t)
      read(length)[0...-1] if length > 0
    when :constant
      case read(:byte)
        when 0 then nil
        when 1 then read(:bool)
        when 3 then read(:number)
        when 4 then read(:string).intern
      end
    when :list
      read(:integer).times.map {yield}
    when :header
      read(12)
    when :instruction
      bytes = read(:size_t)
      opcode = bytes & 0b0011_1111
      bytes >>= 6
      
      register_A = bytes & 0b1111_1111
      register_Bx = bytes >> 8
      
      Lupin::Instruction[opcode].new(register_A, register_Bx)
      #Lupin::Instruction.new(register_A, register_Bx)
    when :function
      f = Lupin::Function.new(@state)
      
      f.name = read(:string)
      f.first_line = read(:integer)
      f.last_line = read(:integer)
      f.upvalue_count = read(:byte)
      f.parameter_count = read(:byte)
      f.is_vararg = read(:byte)
      f.maxstack = read(:byte)
      
      f.instructions = read(:list) {read(:instruction)}
      f.constants = read(:list) {read(:constant)}
      f.functions = read(:list) {read(:function)}
      
      f.lines = read(:list) {read(:integer)}
      f.locals = read(:list) {[read(:string), read(:integer), read(:integer)]}
      f.upvalues = read(:list) {read(:string)}
      
      f.compile
    end
  end
end

class Lupin::State
  def initialize
    @globals = {}
  end
  
  def build_header
    header = "\eLua" # signature
    header << "\x51" # version
    header << "\x00" # format (?)
    header << [1].pack("I")[0] # endian
    header << "\x04\x04\x04\x08" # datatype sizes
    header << "\x00" # integral or floating-point numbers
    
    header
  end
  
  def load (data)
    if data[0] == ?\e
    # treat as binary stream
      stream = Lupin::BinaryStream.new(self, data)
      
      raise "Invalid file header" unless stream.read(:header) == build_header
      
      Lupin::Code.new(stream.read(:function))
    else
      raise "Lua text format isn't supported yet."
    end
  end
  
  def loadfile (filename)
    data = File.read(filename)
    
    # remove shebang
    data[/^[^\n]*\n/] = '' if data[0] == ?#
    
    load(data)
  end
  
  def get_global (name)
    @globals[name]
  end
  
  def set_global (name, value)
    @globals[name] = value
  end
  
  def add (lhs, rhs)
    # Ensure that all Lua numbers are floats
    lhs = lhs.to_f if lhs.is_a?(Integer)
    rhs = rhs.to_f if rhs.is_a?(Integer)
    
    if lhs.is_a?(Numeric) && rhs.is_a?(Numeric)
      lhs + rhs
    else
      left  = Float(lhs) rescue nil if lhs.is_a?(String)
      right = Float(rhs) rescue nil if rhs.is_a?(String)
      
      if left && right
        left + right
      else
        which = (lhs.is_a?(Numeric)) ? lhs : rhs
        raise TypeError, "attempt to perform arithmetic on a #{typeof(which)} value"
      end
    end
  end
  
  def typeof (value)
    case value
    when Numeric then :number
    when String then :string
    when Hash then :table
    when true, false then :boolean
    when nil then :nil
    else :userdata
    end
  end
end

require "pp"

state = Lupin::State.new
state.set_global :print, proc {|*args| puts *args}
state.set_global :test, proc {|*args| [1,2,3]}

def funny (*args)
  args.map {|x| x+42}
end
state.set_global :funny, method(:funny)

function = state.loadfile("luac.out")

puts function.decode
puts function.call
