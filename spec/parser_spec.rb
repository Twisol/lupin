Bundler.setup
require 'lupin'

describe Lupin::Parser do
  AST = Lupin::AST
  
  def parse (*args, &blk)
    Lupin::Parser.parse(*args, &blk)
  end
  
  def check (type, text, value)
    m = parse(text, :root => type)
    m.should_not == nil
    m.should == text
    m.value.should == value
  end
  
  it "matches numbers" do
    check(:number, "10", AST::Number.new(10, 0))
    check(:number, "10.", AST::Number.new(10, 0))
    check(:number, "10e2", AST::Number.new(10, 2))
    check(:number, "10e-1", AST::Number.new(10, -1))
    check(:number, "10.e4", AST::Number.new(10, 4))
    check(:number, ".5", AST::Number.new(0.5, 0))
    check(:number, ".5e2", AST::Number.new(0.5, 2))
    # Negative numbers are handled by the unary minus operator, not as a literal.
  end
  
  it "matches strings" do
    check(:string, "'Hel\\\"lo.'", AST::String.new("Hel\"lo."))
    check(:string, "\"Hel\\'lo.\"", AST::String.new("Hel'lo."))
    check(:string, "[==[foo\\\"bar\\'baz\\r\\n]==]", AST::LongString.new("foo\\\"bar\\'baz\\r\\n"))
  end
end
