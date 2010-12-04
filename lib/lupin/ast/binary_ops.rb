module Lupin::AST
  class BinaryOp
    attr_reader :lhs, :rhs
    
    def initialize (lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end
    
    def == (other)
      self.class == other.class &&
      self.lhs == other.lhs &&
      self.rhs == other.rhs
    end
  end
  
  class Addition < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __add in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :+, 1
    end
  end
  
  class Subtraction < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __sub in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :-, 1
    end
  end
  
  class Multiplication < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __mul in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :*, 1
    end
  end
  
  class Division < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __div in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :/, 1
    end
  end
  
  class Modulo < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __mod in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :%, 1
    end
  end
  
  class Power < BinaryOp
    def bytecode (g)
      # TODO: Implement lookup of __pow in @lhs's metatable
      @lhs.bytecode(g)
      @rhs.bytecode(g)
      g.send :**, 1
    end
  end
  
  OrComp = Class.new(BinaryOp)
  AndComp = Class.new(BinaryOp)
  
  LessThan = Class.new(BinaryOp)
  GreaterThan = Class.new(BinaryOp)
  AtMost = Class.new(BinaryOp)
  AtLeast = Class.new(BinaryOp)
  NotEqual = Class.new(BinaryOp)
  Equal = Class.new(BinaryOp)
  
  Concatenate = Class.new(BinaryOp)
end
