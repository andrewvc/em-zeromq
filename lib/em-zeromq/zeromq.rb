module EventMachine
  module ZeroMQ
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
    end

  end
end
