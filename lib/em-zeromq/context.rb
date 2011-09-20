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

      def socket(socket_type)
        socket_type = find_type(socket_type)
        @context.socket(socket_type)
      end

      def bind(socket_or_type, address, handler = nil, opts = {})
        socket, type = create(socket_or_type, opts)
        socket.bind(address)
        watch(socket, type, address, handler, opts)
      end

      def connect(socket_or_type, address, handler = nil, opts = {})
        socket, type = create(socket_or_type, opts)
        socket.connect(address)
        watch(socket, type, address, handler, opts)
      end

      def watch(socket, socket_type, address, handler, opts = {})
        fd = socket.getsockopt(ZMQ::FD)
        conn = EM.watch(fd, EventMachine::ZeroMQ::Connection, socket, socket_type, address, handler)

        if READABLES.include?(socket_type)
          conn.register_readable
        end

        if WRITABLES.include?(socket_type)
          conn.register_writable
        end

        conn
      end

    private

      def create(socket_or_type, opts = {})
        if socket_or_type.is_a?(ZMQ::Socket)
          socket = socket_or_type
          type = socket_or_type.getsockopt(ZMQ::TYPE)
        else
          type = find_type(socket_or_type)
          socket = @context.socket(type)
        end

        ident = opts.delete(:identity)
        if ident
          socket.setsockopt(ZMQ::IDENTITY, ident)
        end

        unless opts.empty?
          raise "unknown keys: #{opts.keys.join(', ')}"
        end

        [socket, type]
      end

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
