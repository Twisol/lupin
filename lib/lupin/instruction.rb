class Lupin::InstructionSet
  BIAS = (2**18-1)/2
  
  OPCODES = [
    :MOVE, :LOADK, :LOADBOOL, :LOADNIL, :GETUPVAL, :GETGLOBAL, :GETTABLE,
    :SETGLOBAL, :SETUPVAL, :SETTABLE, :NEWTABLE, :SELF, :ADD, :SUB, :MUL, :DIV,
    :MOD, :POW, :UNM, :NOT, :LEN, :CONCAT, :JMP, :EQ, :LT, :LE, :TEST, :TESTSET,
    :CALL, :TAILCALL, :RETURN, :FORLOOP, :FORPREP, :TFORLOOP, :SETLIST, :CLOSE,
    :CLOSURE, :VARARG,
  ]
  
  def initialize (instructions)
    @instructions = instructions
  end
  
  def compile (g)
    pc, length = 0, @instructions.length
    
    while pc < length
      i = @instructions[pc]
      
      g.pre_instruction
      case opcode(i)
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
        binary_op g, i, opcode(i).to_s.downcase
      when :UNM, :NOT, :LEN
        unary_op g, i, opcode(i).to_s.downcase
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
        g.range_get A(i)+1, B(i)-1
        g.call
        g.range_set A(i), C(i)-1
      when :RETURN
        g.range_get A(i), B(i)-1
        g.return
      when :TAILCALL
        g.local_get A(i)
        g.range_get A(i)+1, B(i)-1
        g.tailcall C(i)-1
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
        # Check if the count is still within the limit
        g.local_get A(i)
        g.local_get A(i)+1
        g.lt
        g.jump_if_false 0
        
        # Increment the count by the step
        g.local_get A(i)
        g.local_get A(i)+2
        g.add
        g.push_top
        g.local_set A(i)
        
        # Set the loop index and go back to the start
        g.local_set A(i)+3
        g.jump sBx(i)
      when :TFORLOOP
        # Call the iterator function
        g.local_get A(i)
        g.range_get A(i)+1, 2
        g.call
        g.range_set A(i)+3, C(i)
        
        # Jump if the first return was nil
        g.local_get A(i)+3
        g.push_nil
        g.eq
        g.jump_if_true 1
        
        # Otherwise, set it as the current loop index.
        g.local_get A(i)+3
        g.local_set A(i)+2
      when :NEWTABLE
        g.new_table B(i), C(i)
        g.local_set A(i)
      when :SETLIST
        g.local_get A(i)
        
        block_number = if C(i) == 0
          pc += 1
          g.pre_instruction
          @instructions[pc]
        else
          C(i)
        end
        
        # TODO: Handle the case where B == 0.
        # The wisest thing to do would be to handle this as a
        # compile-time instruction transformation.
        
        start = (block_number-1)*50
        1.upto(B(i)) do |index|
          g.push_top
          g.push_number start+index
          g.local_get A(i)+index
          g.table_set
        end
        
        g.pop
      when :CLOSURE
        upvalues = g.new_closure Bx(i)
        upvalues.times do
          pc += 1
          g.pre_instruction
          
          upvalue = @instructions[pc]
          case opcode(upvalue)
          when :MOVE
            g.share_local B(upvalue)
          when :GETUPVAL
            g.share_upvalue B(upvalue)
          end
        end
        g.local_set A(i)
      when :CLOSE
        g.unshare A(i)
      end
      
      pc += 1
    end
  end
  
  def to_sexp
    @instructions.map do |i|
      type = opcode(i)
      case type
      when :MOVE, :GETUPVAL, :UNM, :NOT, :LEN, :RETURN, :VARARG
        [type, A(i), B(i)]
      when :LOADBOOL, :GETTABLE, :SETTABLE, :ADD, :SUB, :MUL, :DIV, :MOD, :POW,
           :CONCAT, :CALL, :TAILCALL, :SELF, :EQ, :LT, :LE, :TESTSET, :NEWTABLE,
           :SETLIST
        [type, A(i), B(i), C(i)]
      when :LOADK, :GETGLOBAL, :SETGLOBAL, :CLOSURE
        [type, A(i), Bx(i)]
      when :TEST, :TFORLOOP
        [type, A(i), C(i)]
      when :FORPREP, :FORLOOP
        [type, A(i), sBx(i)]
      when :JMP
        [type, sBx(i)]
      when :CLOSE
        [type, A(i)]
      end
    end
  end
  
  def opcode (i)
    OPCODES[i & 0b0011_1111]
  end
  
  def A (i)
    (i >> 6) & 0b1111_1111
  end
  
  def B (i)
    (i >> 23) & 0b1_1111_1111
  end
  
  def C (i)
    (i >> 14) & 0b1_1111_1111
  end
  
  def Bx (i)
    (i >> 14) & 0b11_1111_1111_1111_1111
  end
  
  def sBx (i)
    Bx(i) - BIAS
  end

protected
  def binary_op (g, i, sym)
    g.push_rk B(i)
    g.push_rk C(i)
    g.__send__ sym
    g.local_set A(i)
  end
  
  def unary_op (g, i, sym)
    g.local_get B(i)
    g.__send__ sym
    g.local_set A(i)
  end
end
