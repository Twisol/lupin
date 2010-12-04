module Lupin
  class Compiler
    def self.compile (ast)
      o = Object.new
      Rubinius.object_metaclass(o).dynamic_method :execute do |g|
        ast.bytecode(g)
        g.ret
      end
      o
    end
  end
end
