module Lupin::Types
  class NilClass < Value
    ::Lupin::Types::Nil = new(nil)
    
    def self.new (value)
      Nil
    end
  end
end
