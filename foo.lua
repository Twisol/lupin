do
  local a = 42
  foo = function()
    return a
  end
  print(foo())
  a = 50
end
print(foo())

--print(1,2,3)
