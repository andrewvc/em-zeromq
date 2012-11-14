module EventMachine
  module ZeroMQ
    class Socket < EventMachine::Connection
      READABLES = [ ZMQ::SUB, ZMQ::PULL, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ, ZMQ::PAIR ]
      WRITABLES = [ ZMQ::PUB, ZMQ::PUSH, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ, ZMQ::PAIR ]

      include EventEmitter

      attr_reader   :socket, :socket_type      

      def initialize(socket, socket_type)
        @socket      = socket
        @socket_type = socket_type

        self.notify_readable = true if READABLES.include?(socket_type)
        self.notify_writable = true if WRITABLES.include?(socket_type)
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
        
        EM::next_tick{ notify_readable() }
        
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

      def unbind
        detach
        @socket.close
      end

      def notify_readable
        # Not sure if this is actually necessary. I suppose it prevents us
        # from having to to instantiate a ZMQ::Message unnecessarily.
        # I'm leaving this is because its in the docs, but it could probably
        # be taken out.
        return unless readable?

        while (message = get_message)
          emit(:message, *message)
        end
      end
      
      def notify_writable
        return unless writable?
        
        # one a writable event is successfully received the socket
        # should be accepting messages again so stop triggering
        # write events
        self.notify_writable = false
        
        emit(:writable)
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

      def get_message
        parts = []
        rc = @socket.recvmsgs(parts, ZMQ::NOBLOCK)
        rc >= 0 ? parts : nil
      end
    end
  end
end
