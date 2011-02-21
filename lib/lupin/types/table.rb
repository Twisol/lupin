module Lupin::Types
  class Table < Value
    def initialize (_L)
      @_L = _L
      @hash = Hash.new(Nil)
    end
    
    def [] (key)
      __index = _L.getmetamethod(self, :__index)
      if __index
        __index.call(self, key)
      else
        rawget(key)
      end
    end
    
    def []= (key, value)
      __newindex = _L.getmetamethod(self, :__newindex)
      if __newindex
        __newindex.call(self, key, value)
      else
        rawset(key, value)
      end
    end
    
    def rawget (key)
      @hash[key]
    end
    
    def rawset (key, value)
      @hash[key] = value
    end
    
    def to_s
      str = '{'
      str << @hash.to_a.map {|k, v| "[#{k}] = #{v}"}.join(', ')
      str << '}'
    end
    
  protected
    def _L
      @_L
    end
  end
end
