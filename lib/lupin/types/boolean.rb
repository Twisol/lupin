module Lupin::Types
  class Boolean < Value
    ::Lupin::Types::True = new(true)
    ::Lupin::Types::False = new(false)
    
    def self.new (value)
      value ? True : False
    end
  end
end
