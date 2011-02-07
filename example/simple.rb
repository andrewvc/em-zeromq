require 'rubygems'
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
class EMTestPushHandler
  attr_accessor :connection
  attr_reader   :queue
  
  def initialize
    @queue = []
  end
   
  def on_writable(socket)
    @queue.each do |item|
      socket.send_string item, ZMQ::NOBLOCK
    end
    connection.deregister_writable
  end
end

EM.run do
  ZCTX  = ZMQ::Context.new 1
  send_queue = []


  push_handler = EMTestPushHandler.new
  push = EM::ZeroMQ.create ZCTX, ZMQ::PUSH, :bind, 'tcp://127.0.0.1:2091', push_handler
  push_handler.connection = push
  
  
  pull = EM::ZeroMQ.create ZCTX, ZMQ::PULL, :connect, 'tcp://127.0.0.1:2091', EMTestPullHandler.new
  pull.register_readable
      
  EM::PeriodicTimer.new(1) do
    puts '.'
    push_handler.queue << "Test message #{Time.now}"
    push.register_writable
  end
end

