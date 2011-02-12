require 'rubygems'
$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'em-zeromq'
    
Thread.abort_on_exception = true

class EMTestPullHandler
  attr_reader :received
  def on_readable(socket, messages)
    messages.each do |m|
      print '_'
      # puts m.copy_out_string
    end
  end
end

EM.run do
  reactor = EM::ZeroMQ::Reactor.new(1)
  
  push_socket = reactor.bind( ZMQ::PUSH, 'tcp://127.0.0.1:2091')
  pull_socket = reactor.connect( ZMQ::PULL, 'tcp://127.0.0.1:2091', EMTestPullHandler.new)
  
  n = 0
  
  push_socket.hwm = 40
  
  puts push_socket.hwm
  puts pull_socket.hwm
  
  EM::PeriodicTimer.new(0.01) do
    print '.'
    push_socket.send_string("_#{n += 1}_")
  end
end

