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

      def readable?
        (@socket.getsockopt(ZMQ::EVENTS) & ZMQ::POLLIN) == ZMQ::POLLIN
      end

      def writable?
        return true
        # ZMQ::EVENTS has issues in ZMQ HEAD, we'll ignore this till they're fixed
        # (@socket.getsockopt(ZMQ::EVENTS) & ZMQ::POLLOUT) == ZMQ::POLLOUT
      end

      def notify_readable
        # Not sure if this is actually necessary. I suppose it prevents us
        # from having to to instantiate a ZMQ::Message unnecessarily.
        # I'm leaving this is because its in the docs, but it could probably
        # be taken out.
        return unless readable?
         
        loop do
          msg_parts = []
          msg       = get_message
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

      def notify_writable
        if writable?
          @handler.on_writable(@socket)
        end
      end
 
      # Stop triggering on_writable when socket is writable
      def deregister_writable
        self.notify_writable = false
      end
       
      # Make this socket available for reads
      def register_readable
        # Since ZMQ is event triggered I think this is necessary
        if readable?
          notify_readable
        end
        # Subscribe to EM read notifications
        self.notify_readable = true
      end
     
      # Trigger on_readable when socket is readable
      def register_writable
        # Since ZMQ is event triggered I think this is necessary
        if writable?
          @handler.on_writable(@socket)
        end
        # Subscribe to EM write notifications
        self.notify_writable = true
      end
      
      # Detaches the socket from the EM loop,
      # then closes the socket
      def detach_and_close
        detach
        @socket.close
      end
    end
  end
end
