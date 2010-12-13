module Lupin
  class Value
    attr_reader :value
    
    def initialize (value)
      @value = value
    end
    
    def to_s
      if type == :number
        sprintf("%.14g", @value)
      else
        @value.to_s
      end
    end
    
    def try_tonumber
      return self unless @value.is_a?(String)
      begin
        Lupin::Value.new(Lupin::Parser.parse(@value, :root => :number).value)
      rescue
        self
      end
    end
    
    def type
      case @value
      when nil
        :nil
      when true
        :boolean
      when false
        :boolean
      when Numeric
        :number
      when String
        :string
      else
        :unknown
      end
    end
    
    def getmetatable (lstate)
      key = type
      if type == :table || type == :userdata 
        key = self
      end
      lstate.metatables[key]
    end
    
    def setmetatable (lstate, tbl)
      key = type
      if type == :table || type == :userdata 
        key = self
      end
      lstate.metatables[key] = tbl
    end
    
    ###
    # Primitive operations
    ###
    def + (other)
      Value.new(@value + other.value)
    end
    
    def - (other)
      Value.new(@value - other.value)
    end
    
    def * (other)
      Value.new(@value * other.value)
    end
    
    def / (other)
      Value.new(@value / other.value)
    end
    
    def % (other)
      Value.new(@value % other.value)
    end
    
    def ** (other)
      Value.new(@value ** other.value)
    end
  end
end
