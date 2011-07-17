#!/usr/bin/env ruby
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), "lib")
require "lupin"


state = Lupin::State.new

state.set_global :pairs, proc {|l, t|
  e = t.each
  proc {e.next rescue nil}
}
state.set_global :ipairs, proc {|l, t|
  iter = proc {|l, t, i|
    i += 1
    v = t[i]
    [i, v] unless v == nil
  }
  [iter, t, 0.0]
}
state.set_global :print, proc {|l, *args|
  args = args.map {|arg|
    l.tostring(arg)
  }
  puts args.join("\t")
}
state.set_global :assert, proc {|l, v, message, *args|
  message ||= "assertion failed!"
  raise message unless v
  [v, message, *args]
}
state.set_global :tostring, proc {|l, v|
  l.tostring(v)
}


$L = state

function = state.loadfile("luac.out")
#puts function.decode
puts function.call
