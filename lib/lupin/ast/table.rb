module Lupin::AST
  class Table
    def initialize (fieldlist)
      @fields = fieldlist
    end
  end
  
  class Field
    def initialize (key, val)
      @key, @val = key, val
    end
  end
end
