Bundler.setup
require 'lupin'

describe Lupin::Parser do
  AST = Lupin::AST
  
  def parse (*args, &blk)
    Lupin::Parser.parse(*args, &blk)
  end
  
  def check (type, text)
    m = parse(text, :root => type)
    # Ensure that the AST is what we expected
    m.value.sexp.should == yield
  end
  
  it "matches numbers" do
    check(:number, "10") { 10.0 }
    check(:number, "10.") { 10.0 }
    check(:number, "10e2") { 1000.0 }
    check(:number, "10e-1") { 1.0 }
    check(:number, "10.e4") { 100000.0 }
    check(:number, ".5") { 0.5 }
    check(:number, ".5e2") { 50.0 }
    check(:number, "0xFF") { 0xFF }
    # Negative numbers are handled by the unary minus operator, not as a literal.
  end
  
  it "matches strings" do
    check(:string, "'Hel\\\"lo.'") { "Hel\"lo." }
    check(:string, "\"Hel\\'lo.\"") { "Hel'lo." }
    check(:string, "[==[foo\\\"bar\\'baz\\r\\n]==]") { "foo\\\"bar\\'baz\\r\\n" }
  end
  
  it "matches booleans and nil" do
    check(:boolean, "true") { true }
    check(:boolean, "false") { false }
    check(:nil, "nil") { nil }
  end
  
  it "matches tables" do
    check(:table, "{}") { [:table] }
    check(:table, "{1}") { [:table, [:pair, nil, 1.0]] }
    check(:table, "{1, 2}") {
      [:table, [:pair, nil, 1.0],
               [:pair, nil, 2.0]]
    }
    check(:table, "{foo=1}") { [:table, [:pair, "foo", 1.0]] }
    check(:table, "{[1+1]=1}") { [:table, [:pair, [:+, 1.0, 1.0], 1.0]] }
  end
  
  it "matches binary operations" do
    check(:expression, "1+2+3") { [:+, [:+, 1.0, 2.0], 3.0] }
    check(:expression, "1-2-3") { [:-, [:-, 1.0, 2.0], 3.0] }
    check(:expression, "1*2*3") { [:*, [:*, 1.0, 2.0], 3.0] }
    check(:expression, "1/2/3") { [:/, [:/, 1.0, 2.0], 3.0] }
    check(:expression, "1%2%3") { [:%, [:%, 1.0, 2.0], 3.0] }
    check(:expression, "1^2^3") { [:**, 1.0, [:**, 2.0, 3.0]] }
  end
  
  it "matches unary operations" do
    check(:expression, "--1") { [:-@, [:-@, 1.0]] }
    check(:expression, "not not true") { [:not, [:not, true]] }
  end
  
  it "respects order of operations" do
    check(:expression, "1 - -4 * 6") { [:-, 1, [:*, [:-@, 4.0], 6.0]] }
  end
end
