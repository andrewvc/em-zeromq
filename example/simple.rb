require 'rubygems'
$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'em-zeromq'
    
Thread.abort_on_exception = true

class EMTestPullHandler
  attr_reader :received
  def on_readable(socket, messages)
    messages.each do |m|
      puts m.copy_out_string
    end
  end
end

EM.run do
  ctx = EM::ZeroMQ::Context.new(1)
  
  # setup push sockets
  push_socket1 = ctx.bind( ZMQ::PUSH, 'tcp://127.0.0.1:2091')
  push_socket2 = ctx.bind( ZMQ::PUSH, 'ipc:///tmp/a')
  push_socket3 = ctx.bind( ZMQ::PUSH, 'inproc://simple_test')
  
  # setup one pull sockets listening to both push sockets
  pull_socket = ctx.connect( ZMQ::PULL, 'tcp://127.0.0.1:2091', EMTestPullHandler.new)
  pull_socket.connect('ipc:///tmp/a')
  pull_socket.connect('inproc://simple_test')
  
  n = 0
  
  # push_socket.hwm = 40
  
  # puts push_socket.hwm
  # puts pull_socket.hwm
  
  EM::PeriodicTimer.new(0.1) do
    puts '.'
    push_socket1.send_msg("t#{n += 1}_")
    push_socket2.send_msg("i#{n += 1}_")
    push_socket3.send_msg("p#{n += 1}_")
  end
end

# expected result is :
# .__.__.__.__.__.__.__.__.__.__.__.__.__.__.__.__.__.__.__
#
