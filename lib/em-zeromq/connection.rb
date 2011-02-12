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
      
      def self.map_sockopt(opt, name)
        define_method(name){ @socket.getsockopt(opt) }
        define_method("#{name}="){|val| @socket.setsockopt(opt, val) }
      end
      
      map_sockopt(ZMQ::HWM, :hwm)
      map_sockopt(ZMQ::SWAP, :swap)
      map_sockopt(ZMQ::IDENTITY, :identity)
      map_sockopt(ZMQ::AFFINITY, :affinity)
      map_sockopt(ZMQ::SNDBUF, :sndbuf)
      map_sockopt(ZMQ::RCVBUF, :rcvbuf)
      
      # pgm
      map_sockopt(ZMQ::RATE, :rate)
      map_sockopt(ZMQ::RECOVERY_IVL, :recovery_ivl)
      map_sockopt(ZMQ::MCAST_LOOP, :mcast_loop)
      
      # User method      
      def subscribe(what = '')
        raise "only valid on sub socket type (was #{@socket.name})" unless @socket.name == 'SUB'
        @socket.setsockopt(ZMQ::SUBSCRIBE, what)
      end
      
      def unsubscribe(what)
        raise "only valid on sub socket type (was #{@socket.name})" unless @socket.name == 'SUB'
        @socket.setsockopt(ZMQ::UNSUBSCRIBE, what)
      end
      
      def send_string(*args)
        @socket.send_string(*args)
      end
      
      def send_msg(*parts)
        parts = Array(parts[0]) if parts.size == 0
        
        # multipart
        parts[0...-1].each do |msg|
          @socket.send_string(msg, ZMQ::NOBLOCK | ZMQ::SNDMORE)
        end
        
        @socket.send_string(parts[-1], ZMQ::NOBLOCK)
      end
      
      
      def setsockopt(opt, value)
        @socket.setsockopt(opt, value)
      end
      
      # cleanup when ending loop
      def unbind
        detach_and_close
      end
      
    private
      # internal methods
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
            
            @handler.on_readable(self, msg_parts)
          else
            break
          end
        end
      end
      
      def notify_writable
        return unless writable?
        
        if @handler.respond_to?(:on_writable)
          @handler.on_writable(self)
        end
      end
      
      def get_message
        msg       = ZMQ::Message.new
        msg_recvd = @socket.recv(msg, ZMQ::NOBLOCK)
        msg_recvd ? msg : nil
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
