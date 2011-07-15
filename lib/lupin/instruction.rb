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
  
  
  def compile (g)
    g.pre_instruction
    
    case @type
    when :MOVE
      if g.closing?
        g.ref_local _B
      else
        g.local_get _B
        g.local_set _A
      end
    when :LOADNIL
      g.push_nil
    when :LOADK
      g.push_constant _Bx
      g.local_set _A
    when :LOADBOOL
      g.push_bool _B > 0
      g.local_set _A
      
      g.jump 1 if _C > 0
    when :GETGLOBAL
      g.global_get _Bx
      g.local_set _A
    when :SETGLOBAL
      g.local_get _A
      g.global_set _Bx
    when :GETUPVAL
      if g.closing?
        g.ref_upval _B
      else
        g.upvalue_get _B
        g.local_set _A
      end
    when :SETUPVAL
      g.local_get _A
      g.upvalue_set _B
    when :GETTABLE
      g.local_get _B
      g.push_rk _C
      g.table_get
      g.local_set _A
    when :SETTABLE
      g.local_get _A
      g.push_rk _B
      g.push_rk _C
      g.table_set
    when :ADD, :SUB, :MUL, :DIV, :MOD, :POW
      binary_op g, @type.to_s.downcase
    when :UNM, :NOT, :LEN
      unary_op g, @type.to_s.downcase
    when :CONCAT
      _B.upto(_C) do |i|
        g.local_get i
      end
      g.concat _C-_B+1
      g.local_set _A
    when :JMP
      g.jump _sBx
    when :CALL
      g.local_get _A
      g.call _A, _B-1, _C-1
    when :RETURN
      g.return _A, _B-1
    when :TAILCALL
      g.local_get _A
      g.tailcall _A, _B-1, _C-1
    when :VARARG
      g.vararg _A, _B-1
    when :SELF
      g.local_get _B
      g.push_top
      g.push_rk _C
      g.table_get
      g.local_set _A+1
      g.local_set _A
    when :EQ
      g.push_rk _B
      g.push_rk _C
      g.eq
      if _A == 0
        g.jump_if_true 1
      else
        g.jump_if_false 1
      end
    when :LT
      g.push_rk _B
      g.push_rk _C
      g.lt
      if _A == 0
        g.jump_if_true 1
      else
        g.jump_if_false 1
      end
    when :LE
      g.push_rk _B
      g.push_rk _C
      g.le
      if _A == 0
        g.jump_if_true 1
      else
        g.jump_if_false 1
      end
    when :TEST
      g.local_get _A
      if _C == 0
        g.jump_if_false 1
      else
        g.jump_if_true 1
      end
    when :TESTSET
      g.local_get _B
      
      g.push_top
      if _C == 0
        g.jump_if_false 1
      else
        g.jump_if_true 1
      end
      
      g.local_set _A
    when :FORPREP
      g.local_get _A
      g.local_get _A+2
      g.sub
      g.local_set _A
      
      g.jump _sBx
    when :FORLOOP
      # Increment the count by the step
      g.local_get _A
      g.local_get _A+2
      g.add
      g.push_top
      g.local_set _A
      
      # Check if the count is still within the limit
      g.local_get _A+1
      g.lt
      g.jump_if_false 0
      
      # Set the loop index and go back to the start
      g.local_get _A
      g.local_set _A+3
      g.jump _sBx
    when :TFORLOOP
      g.tforloop _A, _C
    when :NEWTABLE
      g.new_table _B, _C
      g.local_set _A
    when :SETLIST
      g.local_get _A
      
      start = (_C-1)*50
      1.upto(_B) do |i|
        g.push_top
        g.push_number start+i
        g.local_get _A+i
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
      g.new_closure _Bx
      g.local_set _A
    when :CLOSE
      g.unref_locals _A
    end
  end

protected
  def binary_op (g, sym)
    g.push_rk _B
    g.push_rk _C
    g.__send__ sym
    g.local_set _A
  end
  
  def unary_op (g, sym)
    g.local_get _B
    g.__send__ sym
    g.local_set _A
  end
end
