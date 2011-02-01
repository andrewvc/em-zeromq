
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
        messages = []
        
        #complete_messages = (@socket.getsockopt(ZMQ::EVENTS) & ZMQ::POLLIN) == ZMQ::POLLIN
        loop do
          msg = ZMQ::Message.new
          break unless @socket.recv(msg, ZMQ::NOBLOCK)
          
          messages << msg
           
          if @socket.more_parts?
            next
          else
            @handler.on_readable(@socket, messages)
            messages = []
          end
        end
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
