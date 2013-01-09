require 'eventmachine'
require 'ffi-rzmq'

# compatibilty hacks for zmq 2.x/3.x
module ZMQ
  if LibZMQ.version3?
    NOBLOCK = DONTWAIT
  end
end

module EmZeromq

end

require 'em-zeromq/context'
require 'em-zeromq/event_emitter'
require 'em-zeromq/socket'
