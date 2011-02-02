
module EventMachine
  module ZeroMQ
    class Connection < EventMachine::Connection
      attr_accessor :on_readable, :on_writable, :handler
      attr_reader   :socket, :socket_type, :address

      def initialize(socket, socket_type, address, handler)
        @socket      = socket
        @socket_type = socket_type
        @handler     = handler
        @address     = address
      end

      def notify_readable
        return unless read_capable?
        #return unless (@socket.getsockopt(ZMQ::EVENTS) & ZMQ::POLLOUT) == ZMQ::POLLOUT
         
        msg_parts = []

        loop do
          msg = get_message
          if msg
            msg_parts << msg
            while @socket.more_parts?
              msg = get_message
              if msg
                msg_parts << msg
              else
                raise "Multi-part message missing a message!"
              end
            end
            
            @handler.on_readable(@socket, msg_parts)
          else
            break
          end
        end
      end
      
      def get_message
        msg       = ZMQ::Message.new
        msg_recvd = @socket.recv(msg, ZMQ::NOBLOCK)
        msg_recvd ? msg : nil
      end

      def deregister_writable
        self.notify_writable = false
      end
      
      def register_writable
        if (@socket.getsockopt(ZMQ::EVENTS) & ZMQ::POLLOUT) == ZMQ::POLLOUT
          notify_writable
        end
        self.notify_writable = true
      end
      
      def notify_writable
        @handler.on_writable(@socket)
      end
      
      private
      
      def read_capable?
        @read_capable  ||= EM::ZeroMQ::READABLE_TYPES.include? @socket_type
      end

      def write_capable?
        @write_capable ||= EM::ZeroMQ::WRITABLE_TYPES.include? @socket_type
      end
    end
  end
end
