module Lupin::Types
  class String < Value
    def to_number
      m = Lupin::Parser.parse(@value, :root => :number)
      return Nil unless m.to_s == @value
      Lupin::Compiler.compile(m.value).invoke
    end
  end
end
