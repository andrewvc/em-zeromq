# This example shows how to use setsockopt to set the linger period for socket
# shutdown. This is useful since by default pending meesages will block the
# termination of the ZMQ context.

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  push = zmq.socket(ZMQ::PUSH)
  push.setsockopt(ZMQ::LINGER, 0)

  push.connect("ipc:///tmp/foo")

  push.send_msg('hello')

  Signal.trap('INT') {
    puts 'Trapped INT signal. Stopping eventmachine'
    EM.stop
  }
}
