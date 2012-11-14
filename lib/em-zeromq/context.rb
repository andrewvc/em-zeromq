#
# different ways to create a socket:
# ctx.bind(:xreq, 'tcp://127.0.0.1:6666')
# ctx.bind('xreq', 'tcp://127.0.0.1:6666')
# ctx.bind(ZMQ::XREQ, 'tcp://127.0.0.1:6666')
#
module EventMachine
  module ZeroMQ
    class Context

      
      def initialize(threads_or_context)
        if threads_or_context.is_a?(ZMQ::Context)
          @context = threads_or_context
        else
          @context = ZMQ::Context.new(threads_or_context)
        end
      end
      
      ##
      # Create a socket in this context.
      # 
      # @param [Integer] socket_type One of ZMQ::REQ, ZMQ::REP, ZMQ::PULL, ZMQ::PUSH,
      #   ZMQ::ROUTER, ZMQ::DEALER
      # 
      # 
      def socket(socket_type)
        zmq_socket = @context.socket(socket_type)
        
        fd = []
        if zmq_socket.getsockopt(ZMQ::FD, fd) < 0
          raise "Unable to get socket FD: #{ZMQ::Util.error_string}"
        end
        
        EM.watch(fd[0], EventMachine::ZeroMQ::Socket, zmq_socket, socket_type)
      end
      
    end
    
  end
end
