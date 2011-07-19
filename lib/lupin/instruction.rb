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
        g.pop
      when :LOADNIL
        g.push_nil
      when :LOADK
        g.push_constant Bx(i)
        g.local_set A(i)
        g.pop
      when :LOADBOOL
        g.push_bool B(i) > 0
        g.local_set A(i)
        g.pop
        
        g.jump 1 if C(i) > 0
      when :GETGLOBAL
        g.push_constant Bx(i)
        g.global_get
        g.local_set A(i)
        g.pop
      when :SETGLOBAL
        g.push_constant Bx(i)
        g.local_get A(i)
        g.global_set
        g.pop
      when :GETUPVAL
        g.upvalue_get B(i)
        g.local_set A(i)
        g.pop
      when :SETUPVAL
        g.local_get A(i)
        g.upvalue_set B(i)
        g.pop
      when :GETTABLE
        g.local_get B(i)
        g.push_rk C(i)
        g.table_get
        g.local_set A(i)
        g.pop
      when :SETTABLE
        g.local_get A(i)
        g.push_rk B(i)
        g.push_rk C(i)
        g.table_set
        g.pop
      when :ADD, :SUB, :MUL, :DIV, :MOD, :POW
        binary_op g, i, opcode(i).to_s.downcase
      when :UNM, :LEN
        unary_op g, i, opcode(i).to_s.downcase
      when :NOT
        if_else proc {
          push_bool false
        }, proc {
          push_bool true
        }
      when :CONCAT
        g.range_get B(i), C(i)-B(i)+1
        g.concat
        g.local_set A(i)
        g.pop
      when :JMP
        g.jump sBx(i)
      when :CALL
        g.local_get A(i)
        g.range_get A(i)+1, B(i)-1
        g.call
        g.range_set A(i), C(i)-1
        g.pop
      when :RETURN
        g.range_get A(i), B(i)-1
        g.return
      when :TAILCALL
        # Rubinius doesn't support tailcalls, so this is currently
        # just a call-and-return.
        g.local_get A(i)
        g.range_get A(i)+1, B(i)-1
        g.call
        g.return
      when :VARARG
        g.vararg A(i), B(i)-1
      when :SELF
        g.local_get B(i)
        g.local_set A(i)+1
        g.push_rk C(i)
        g.table_get
        g.local_set A(i)
        g.pop
      when :EQ
        g.push_rk B(i)
        g.push_rk C(i)
        g.eq
        g.jump 1, (A(i) == 0)
      when :LT
        g.push_rk B(i)
        g.push_rk C(i)
        g.lt
        g.jump 1, (A(i) == 0)
      when :LE
        g.push_rk B(i)
        g.push_rk C(i)
        g.le
        g.jump 1, (A(i) == 0)
      when :TEST
        g.local_get A(i)
        g.jump 1, (C(i) != 0)
      when :TESTSET
        g.local_get B(i)
        g.jump 1, C(i) != 0
        
        g.local_get B(i)
        g.local_set A(i)
        g.pop
      when :FORPREP
        # Negative step for prep
        g.local_get A(i)
        g.local_get A(i)+2
        g.sub
        g.local_set A(i)
        g.pop
        
        # Jump to the associated FORLOOP instruction
        g.jump sBx(i)
      when :FORLOOP
        # Do the conditional check
        g.local_get A(i)
        g.local_get A(i)+1
        
        g.local_get A(i)+2
        g.push_number 0.0
        g.lt
        g.if_else proc{
          # If the step is negative, switch count < limit to limit < count
          g.move_down 1
        }
        
        g.lt
        g.jump_if_false 0  # Break out of the loop
        
        # Increment the count
        g.local_get A(i)
        g.local_get A(i)+2
        g.add
        g.local_set A(i)
        g.local_set A(i)+3  # Set it to the visible loop local.
        g.pop
        
        # Go to the top of the loop
        g.jump sBx(i)
      when :TFORLOOP
        # Call the iterator function
        g.local_get A(i)
        g.range_get A(i)+1, 2
        g.call
        g.range_set A(i)+3, C(i)
        g.pop
        
        # Jump if the first return was nil
        g.local_get A(i)+3
        g.push_nil
        g.eq
        g.jump_if_true 1
        
        # Otherwise, set it as the current loop index.
        g.local_get A(i)+3
        g.local_set A(i)+2
        g.pop
      when :NEWTABLE
        g.new_table B(i), C(i)
        g.local_set A(i)
        g.pop
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
          g.pop
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
        g.pop
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
