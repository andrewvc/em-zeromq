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
  def on_writable(socket)
  end
end
EM.run do
  ZCTX  = ZMQ::Context.new 1
  push = EM::ZeroMQ.create ZCTX, ZMQ::PUSH, :bind, 'tcp://127.0.0.1:2091', EMTestPushHandler.new
  pull = EM::ZeroMQ.create ZCTX, ZMQ::PULL, :connect, 'tcp://127.0.0.1:2091', EMTestPullHandler.new
      
  EM::PeriodicTimer.new(1) {
    push.socket.send_string "Hello World! #{Time.now}", ZMQ::NOBLOCK
  }
end

