module Lupin::Types
  class Table < Value
    def initialize
      @hash = {}
    end
    
    def [] (key)
      @hash[key]
    end
    
    def []= (key, value)
      @hash[key] = value
    end
    
    def to_s
      str = '{'
      str << @hash.to_a.map {|k, v| "[#{k}] = #{v}"}.join(', ')
      str << '}'
    end
  end
end
