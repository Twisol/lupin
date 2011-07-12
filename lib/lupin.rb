module Lupin
  [:instruction, :generator, :function, :binary_reader, :state].each do |file|
    require "lupin/#{file}"
  end
end
