module EventMachine
  module ZeroMQ
    READABLE_TYPES = [ZMQ::SUB, ZMQ::PULL, ZMQ::REQ, ZMQ::REP, ZMQ::XREQ, ZMQ::XREP, ZMQ::PAIR]
    WRITABLE_TYPES = [ZMQ::PUB, ZMQ::PUSH, ZMQ::REQ, ZMQ::REP, ZMQ::XREQ, ZMQ::XREP, ZMQ::PAIR]

     def self.create(context, socket_type, bind_or_connect, address, handler)
      socket = context.socket socket_type
       
      unless [:bind, :connect].include?(bind_or_connect)
        raise ArgumentError, "Invalid Option '#{bind_or_connect}' try :bind or :connect"
      end
       
      if bind_or_connect == :bind
        socket.bind address
      else
        socket.connect address
      end
       
      conn = EM.watch(socket.getsockopt(ZMQ::FD), EventMachine::ZeroMQ::Connection, socket, socket_type, address, handler)
      conn.notify_readable = true if EM::ZeroMQ::READABLE_TYPES.include? socket_type
      
      #Given the nature of ZMQ this isn't that useful, and will generally
      #cause perf problems as it repeatedly triggers. If people really want to
      #use it, they should do so explicitly
      conn.notify_writable = false
      conn
    end

  end
end
