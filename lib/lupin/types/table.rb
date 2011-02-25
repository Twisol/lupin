module Lupin::Types
  class Table < Value
    def initialize
      @hash = Hash.new(Nil)
    end
    
    def [] (key)
      rawget(key)
    end
    
    def []= (key, value)
      rawset(key, value)
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
    
    def value
      @hash
    end
  end
end
