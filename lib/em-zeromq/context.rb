#
# different ways to create a socket:
# ctx.bind(:xreq, 'tcp://127.0.0.1:6666')
# ctx.bind('xreq', 'tcp://127.0.0.1:6666')
# ctx.bind(ZMQ::XREQ, 'tcp://127.0.0.1:6666')
#
module EventMachine
  module ZeroMQ
    class Context
      READABLES = [ ZMQ::SUB, ZMQ::PULL, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ ]
      WRITABLES = [ ZMQ::PUB, ZMQ::PUSH, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ ]
      
      def initialize(threads_or_context)
        if threads_or_context.is_a?(ZMQ::Context)
          @context = threads_or_context
        else
          @context = ZMQ::Context.new(threads_or_context)
        end
      end

      def bind(socket_type, address, handler = nil, opts = {})
        create(socket_type, :bind, address, handler, opts)
      end

      def connect(socket_type, address, handler = nil, opts = {})
        create(socket_type, :connect, address, handler, opts)
      end
      
      def create(socket_type, bind_or_connect, address, handler, opts = {})
        socket_type = find_type(socket_type)
        socket = @context.socket(socket_type)
        
        ident = opts.delete(:identity)
        if ident
          socket.setsockopt(ZMQ::IDENTITY, ident)
        end
        
        unless opts.empty?
          raise "unknown keys: #{opts.keys.join(', ')}"
        end

        if bind_or_connect == :bind
          socket.bind(address)
        else
          socket.connect(address)
        end

        conn = EM.watch(socket.getsockopt(ZMQ::FD), EventMachine::ZeroMQ::Connection, socket, socket_type, address, handler)

        if READABLES.include?(socket_type)
          conn.register_readable
        end
        
        if WRITABLES.include?(socket_type)
          conn.register_writable
        end

        conn
      end
      
    private
      def find_type(type)
        if type.is_a?(Symbol) or type.is_a?(String)
          ZMQ.const_get(type.to_s.upcase)
        else
          type
        end
      end
      
    end

  end
end
