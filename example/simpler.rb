# Simpler than simple.rb ;)

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  push = zmq.socket(ZMQ::PUSH)
  push.connect("ipc:///tmp/foo")

  pull = zmq.socket(ZMQ::PULL)
  pull.bind("ipc:///tmp/foo")

  pull.on(:message) { |part|
    puts part.copy_out_string
  }

  EM.add_periodic_timer(1) {
    push.send_msg("Hello")
  }
}
