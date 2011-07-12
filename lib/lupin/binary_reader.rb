class Lupin::BinaryReader
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