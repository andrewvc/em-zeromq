require 'rubygems'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'em-zeromq'
    
Thread.abort_on_exception = true

trap('INT') do
  EM::stop()
end

puts "Started (with zmq #{ZMQ::Util.version.join('.')})."

ctx = EM::ZeroMQ::Context.new(1)

EM.run do
  # setup push sockets
  push_socket1 = ctx.socket(ZMQ::PUSH)
  
  push_socket1.hwm = 40
  puts "HWM: #{push_socket1.hwm}"
  
  push_socket1.bind('tcp://127.0.0.1:2091')
  
  push_socket2 = ctx.socket(ZMQ::PUSH)
  push_socket2.bind('ipc:///tmp/a')
  
  push_socket3 = ctx.socket(ZMQ::PUSH)
  push_socket3.bind('inproc://simple_test')
  
  # setup one pull sockets listening to all push sockets
  pull_socket = ctx.socket(ZMQ::PULL)
  pull_socket.connect('tcp://127.0.0.1:2091')
  pull_socket.connect('ipc:///tmp/a')
  pull_socket.connect('inproc://simple_test')
  
  pull_socket.on(:message) { |*parts|
    parts.each do |m|
      puts m.copy_out_string
    end
  }

  n = 0
  
  EM::PeriodicTimer.new(0.1) do
    puts '.'
    push_socket1.send_msg("t#{n += 1}_")
    push_socket2.send_msg("i#{n += 1}_")
    push_socket3.send_msg("p#{n += 1}_")
  end
end

puts "Completed."
