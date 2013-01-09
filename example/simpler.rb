# Simpler than simple.rb ;)

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  push = zmq.socket(ZMQ::PUSH)
  push.connect("tcp://127.0.0.1:2091")

  pull = zmq.socket(ZMQ::PULL)
  pull.bind("tcp://127.0.0.1:2091")

  pull.on(:message) { |part|
    puts part.copy_out_string
    part.close
  }

  EM.add_periodic_timer(1) {
    push.send_msg("Hello")
  }
}
