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
      stream = Lupin::BinaryReader.new(self, data)
      
      raise "Invalid file header" unless stream.read(:header) == build_header
      
      Lupin::Function.new(stream.read(:prototype))
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
  
  
  ### Primitive operations
  
  def get_global (name)
    @globals[name]
  end
  
  def set_global (name, value)
    @globals[name] = value
  end
  
  def add (lhs, rhs)
    arith_op :+, lhs, rhs
  end
  
  def sub (lhs, rhs)
    arith_op :-, lhs, rhs
  end
  
  def mul (lhs, rhs)
    arith_op :*, lhs, rhs
  end
  
  def div (lhs, rhs)
    arith_op :/, lhs, rhs
  end
  
  def mod (lhs, rhs)
    arith_op :%, lhs, rhs
  end
  
  def pow (lhs, rhs)
    arith_op :**, lhs, rhs
  end
  
  def unm (lhs, rhs)
    lhs_num = tonumber(lhs)
    if lhs_num
      -lhs_num
    else
      # TODO: try metatable
      raise TypeError, "attempt to perform arithmetic on a #{typeof(lhs)} value"
    end
  end
  
  def lt (lhs, rhs)
    if typeof(lhs) != typeof(rhs)
      raise TypeError, "attempt to compare #{typeof(lhs)} with #{typeof(rhs)}"
    elsif lhs.is_a?(String) or lhs.is_a?(Numeric)
      lhs < rhs
    else
      # TODO: try metatable
      raise TypeError, "attempt to compare two #{typeof(lhs)} values"
    end
  end
  
  def le (lhs, rhs)
    if typeof(lhs) != typeof(rhs)
      raise TypeError, "attempt to compare #{typeof(lhs)} with #{typeof(rhs)}"
    elsif lhs.is_a?(String) or lhs.is_a?(Numeric)
      lhs < rhs
    else
      # TODO: try metatable
      raise TypeError, "attempt to compare two #{typeof(lhs)} values"
    end
  end
  
  def eq (lhs, rhs)
    return false if typeof(lhs) != typeof(rhs)
    
    case typeof(lhs)
    when :string, :number, :boolean, :nil
      lhs == rhs
    when :lightuserdata
      lhs.object_id == rhs.object_id
    when :table, :userdata
      # TODO: try metatable
      lhs.object_id == rhs.object_id
    end
  end
  
  def concat (values)
    values.reduce("") do |acc, value|
      value_num = tonumber(value)
      if value_num
        acc << v
      else
        # TODO: try metatable
        raise TypeError, "attempt to concatenate a #{typeof(value)} value"
      end
      acc
    end
  end
  
  def len (value)
    case typeof(value)
    when :string
      value.length
    when :table
      i = 0
      i += 1 until value[i] == nil
      i
    else
      # TODO: try metatable
      raise TypeError, "attempt to get length of a #{typeof(value)} value"
    end
  end
  
  def index (table, key)
    if typeof(table) == :table
      table[key]
    else
      # TODO: try metatable
      raise TypeError, "attempt to index a #{typeof(table)} value"
    end
  end
  
  def newindex (table, key, value)
    if typeof(table) == :table
      table[key] = value
    else
      # TODO: try metatable
      raise TypeError, "attempt to index a #{typeof(table)} value"
    end
  end
  
  def call (f, args)
    if typeof(f) == :function
      result = f.call(*args)
      result = [result] unless result.is_a?(Array)
      result
    else
      # TODO: try metatable
      raise TypeError, "attempt to call a #{typeof(f)} value"
    end
  end
  
  
  def typeof (value)
    case value
    when Method, Proc, Lupin::Function then :function
    when Numeric then :number
    when String then :string
    when Hash then :table
    when true, false then :boolean
    when nil then :nil
    else :userdata
    end
  end
  
  def tonumber (value)
    case value
    when Numeric
      value.to_f
    when String
      # TODO: Replace with a parser that handles Lua's numeric literal quirks.
      Float(value) rescue nil
    else
      nil
    end
  end
  
protected
  def arith_op (op, lhs, rhs)
    lhs_num = tonumber(lhs)
    rhs_num = tonumber(rhs)
    
    if lhs_num && rhs_num
      lhs_num.__send__(op, rhs_num)
    else
      # TODO: try metatable
      which = (lhs.is_a?(Numeric)) ? rhs : lhs
      raise TypeError, "attempt to perform arithmetic on a #{typeof(which)} value"
    end
  end
end
