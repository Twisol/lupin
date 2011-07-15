class Lupin::Instruction
  BIAS = (2**18-1)/2
  
  OPCODES = [
    :MOVE, :LOADK, :LOADBOOL, :LOADNIL, :GETUPVAL, :GETGLOBAL, :GETTABLE,
    :SETGLOBAL, :SETUPVAL, :SETTABLE, :NEWTABLE, :SELF, :ADD, :SUB, :MUL, :DIV,
    :MOD, :POW, :UNM, :NOT, :LEN, :CONCAT, :JMP, :EQ, :LT, :LE, :TEST, :TESTSET,
    :CALL, :TAILCALL, :RETURN, :FORLOOP, :FORPREP, :TFORLOOP, :SETLIST, :CLOSE,
    :CLOSURE, :VARARG,
  ]
  
  def initialize (bytes)
    @type = OPCODES[bytes & 0b0011_1111]
    bytes >>= 6
    
    @A = bytes & 0b1111_1111
    @Bx = bytes >> 8
  end
  
  def to_sexp
    case @type
    when :MOVE, :GETUPVAL, :UNM, :NOT, :LEN, :RETURN, :VARARG
      [@type, _A, _B]
    when :LOADBOOL, :GETTABLE, :SETTABLE, :ADD, :SUB, :MUL, :DIV, :MOD, :POW,
         :CONCAT, :CALL, :TAILCALL, :SELF, :EQ, :LT, :LE, :TESTSET, :NEWTABLE,
         :SETLIST
      [@type, _A, _B, _C]
    when :LOADK, :GETGLOBAL, :SETGLOBAL, :CLOSURE
      [@type, _A, _Bx]
    when :TEST, :TFORLOOP
      [@type, _A, _C]
    when :FORPREP, :FORLOOP
      [@type, _A, _sBx]
    when :JMP
      [@type, _sBx]
    when :CLOSE
      [@type, _A]
    end
  end
  
  def opcode
    @type
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

class Lupin::InstructionSet
  def initialize (instructions)
    @instructions = instructions
  end
  
  def compile (g)
    pc, length = 0, @instructions.length
    
    while pc < length
      i = @instructions[pc]
      
      g.pre_instruction
      case i.opcode
      when :MOVE
        g.local_get B(i)
        g.local_set A(i)
      when :LOADNIL
        g.push_nil
      when :LOADK
        g.push_constant Bx(i)
        g.local_set A(i)
      when :LOADBOOL
        g.push_bool B(i) > 0
        g.local_set A(i)
        
        g.jump 1 if C(i) > 0
      when :GETGLOBAL
        g.global_get Bx(i)
        g.local_set A(i)
      when :SETGLOBAL
        g.local_get A(i)
        g.global_set Bx(i)
      when :GETUPVAL
        g.upvalue_get B(i)
        g.local_set A(i)
      when :SETUPVAL
        g.local_get A(i)
        g.upvalue_set B(i)
      when :GETTABLE
        g.local_get B(i)
        g.push_rk C(i)
        g.table_get
        g.local_set A(i)
      when :SETTABLE
        g.local_get A(i)
        g.push_rk B(i)
        g.push_rk C(i)
        g.table_set
      when :ADD, :SUB, :MUL, :DIV, :MOD, :POW
        binary_op g, @type.to_s.downcase
      when :UNM, :NOT, :LEN
        unary_op g, @type.to_s.downcase
      when :CONCAT
        B(i).upto(C(i)) do |i|
          g.local_get i
        end
        g.concat C(i)-B(i)+1
        g.local_set A(i)
      when :JMP
        g.jump sBx(i)
      when :CALL
        g.local_get A(i)
        g.call A(i), B(i)-1, C(i)-1
      when :RETURN
        g.return A(i), B(i)-1
      when :TAILCALL
        g.local_get A(i)
        g.tailcall A(i), B(i)-1, C(i)-1
      when :VARARG
        g.vararg A(i), B(i)-1
      when :SELF
        g.local_get B(i)
        g.push_top
        g.push_rk C(i)
        g.table_get
        g.local_set A(i)+1
        g.local_set A(i)
      when :EQ
        g.push_rk B(i)
        g.push_rk C(i)
        g.eq
        if A(i) == 0
          g.jump_if_true 1
        else
          g.jump_if_false 1
        end
      when :LT
        g.push_rk B(i)
        g.push_rk C(i)
        g.lt
        if A(i) == 0
          g.jump_if_true 1
        else
          g.jump_if_false 1
        end
      when :LE
        g.push_rk B(i)
        g.push_rk C(i)
        g.le
        if A(i) == 0
          g.jump_if_true 1
        else
          g.jump_if_false 1
        end
      when :TEST
        g.local_get A(i)
        if C(i) == 0
          g.jump_if_false 1
        else
          g.jump_if_true 1
        end
      when :TESTSET
        g.local_get B(i)
        
        g.push_top
        if C(i) == 0
          g.jump_if_false 1
        else
          g.jump_if_true 1
        end
        
        g.local_set A(i)
      when :FORPREP
        g.local_get A(i)
        g.local_get A(i)+2
        g.sub
        g.local_set A(i)
        
        g.jump sBx(i)
      when :FORLOOP
        # Increment the count by the step
        g.local_get A(i)
        g.local_get A(i)+2
        g.add
        g.push_top
        g.local_set A(i)
        
        # Check if the count is still within the limit
        g.local_get A(i)+1
        g.lt
        g.jump_if_false 0
        
        # Set the loop index and go back to the start
        g.local_get A(i)
        g.local_set A(i)+3
        g.jump sBx(i)
      when :TFORLOOP
        g.tforloop A(i), C(i)
      when :NEWTABLE
        g.new_table B(i), C(i)
        g.local_set A(i)
      when :SETLIST
        g.local_get A(i)
        
        start = (C(i)-1)*50
        1.upto(B(i)) do |i|
          g.push_top
          g.push_number start+i
          g.local_get A(i)+i
          g.table_set
        end
        
        g.pop
        
        # TODO: If C is 0, cast the next instruction to an integer and use
        # it as the C value.
        # One way to do this is to move this whole compile method into
        # Lupin::Prototype so we have access to the instruction list.
        # Another is to do a precompile transform if C is 0, replacing both
        # instructions with a single custom instruction.
      when :CLOSURE
        upvalues = g.new_closure Bx(i)
        upvalues.times do
          pc += 1
          
          upvalue = @instructions[pc]
          case upvalue.opcode
          when :MOVE
            g.local_ref B(upvalue)
          when :GETUPVAL
            g.upval_ref B(upvalue)
          end
        end
        g.local_set A(i)
      when :CLOSE
        g.unref_locals A(i)
      end
      
      pc += 1
    end
  end
  
  def to_sexp
    @instructions.map {|i| i.to_sexp}
  end
  
  def A (i)
    i._A
  end
  
  def B (i)
    i._B
  end
  
  def C (i)
    i._C
  end
  
  def Bx (i)
    i._Bx
  end
  
  def sBx (i)
    i._sBx
  end

protected
  def binary_op (g, sym)
    g.push_rk B(i)
    g.push_rk C(i)
    g.__send__ sym
    g.local_set A(i)
  end
  
  def unary_op (g, sym)
    g.local_get B(i)
    g.__send__ sym
    g.local_set A(i)
  end
end
