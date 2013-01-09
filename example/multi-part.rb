# This example shows how one might deal with sending and recieving multi-part
# messages

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  pull = zmq.socket(ZMQ::PULL)
  pull.bind("ipc:///tmp/test")

  pull.on(:message) { |part1, part2|
    p [:part1, part1.copy_out_string, :part2, part2.copy_out_string]
    part1.close
    part2.close
  }

  pull.on(:message) { |*parts|
    p [:parts, parts.map(&:copy_out_string)]
    parts.each(&:close)
  }

  push = zmq.socket(ZMQ::PUSH)
  push.connect("ipc:///tmp/test")

  i = 0
  EM.add_periodic_timer(1) {
    puts "Sending 2-part message"
    i += 1
    push.send_msg("hello #{i}", "second part")
  }
}
