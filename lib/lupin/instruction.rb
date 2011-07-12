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
    g.closure _A, _Bx
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
