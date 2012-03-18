module EventMachine
  module ZeroMQ
    class Socket < EventMachine::Connection
      attr_accessor :on_readable, :on_writable, :handler
      attr_reader   :socket, :socket_type      

      def initialize(socket, socket_type, handler)
        @socket      = socket
        @socket_type = socket_type
        @handler     = handler
      end
      
      def self.map_sockopt(opt, name)
        define_method(name){ getsockopt(opt) }
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
      def bind(address)
        @socket.bind(address)
      end
      
      def connect(address)
        @socket.connect(address)
      end
      
      def subscribe(what = '')
        raise "only valid on sub socket type (was #{@socket.name})" unless @socket.name == 'SUB'
        @socket.setsockopt(ZMQ::SUBSCRIBE, what)
      end
      
      def unsubscribe(what)
        raise "only valid on sub socket type (was #{@socket.name})" unless @socket.name == 'SUB'
        @socket.setsockopt(ZMQ::UNSUBSCRIBE, what)
      end
      
      # send a non blocking message
      # parts:  if only one argument is given a signle part message is sent
      #         if more than one arguments is given a multipart message is sent
      #
      # return: true is message was queued, false otherwise
      #
      def send_msg(*parts)
        parts = Array(parts[0]) if parts.size == 0
        sent = true
        
        # multipart
        parts[0...-1].each do |msg|
          sent = @socket.send_string(msg, ZMQ::NOBLOCK | ZMQ::SNDMORE)
          if sent == false
            break
          end
        end
        
        if sent
          # all the previous parts were queued, send
          # the last one
          ret = @socket.send_string(parts[-1], ZMQ::NOBLOCK)
          if ret < 0
            raise "Unable to send message: #{ZMQ::Util.error_string}"
          end
        else
          # error while sending the previous parts
          # register the socket for writability
          self.notify_writable = true
          sent = false
        end
        
        notify_readable()
        
        sent
      end
      
      def getsockopt(opt)
        ret = []
        rc = @socket.getsockopt(opt, ret)
        unless ZMQ::Util.resultcode_ok?(rc)
          raise ZMQOperationFailed, "getsockopt: #{ZMQ::Util.error_string}"
        end

        (ret.size == 1) ? ret[0] : ret    
      end
      
      def setsockopt(opt, value)
        @socket.setsockopt(opt, value)
      end
      
      # cleanup when ending loop
      def unbind
        detach_and_close
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
        # Subscribe to EM write notifications
        self.notify_writable = true
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
        
        # one a writable event is successfully received the socket
        # should be accepting messages again so stop triggering
        # write events
        self.notify_writable = false
        
        if @handler.respond_to?(:on_writable)
          @handler.on_writable(self)
        end
      end
      def readable?
        (getsockopt(ZMQ::EVENTS) & ZMQ::POLLIN) == ZMQ::POLLIN
      end

      def writable?
        return true
        # ZMQ::EVENTS has issues in ZMQ HEAD, we'll ignore this till they're fixed
        # (getsockopt(ZMQ::EVENTS) & ZMQ::POLLOUT) == ZMQ::POLLOUT
      end
     
    private
    
      # internal methods

      def get_message
        msg       = ZMQ::Message.new
        msg_recvd = @socket.recvmsg(msg, ZMQ::NOBLOCK)
        msg_recvd != -1 ? msg : nil
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
