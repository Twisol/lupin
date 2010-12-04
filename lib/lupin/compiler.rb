module Lupin
  class Compiler
    def self.compile (ast, g=Rubinius::Generator.new)
      ast.bytecode (g)
    end
  end
end
