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
