# em-zeromq #

Low level event machine support for ZeroMQ

## Description: ##

This seems to work fine, no memory leaks, and it runs fast.
It may not be perfect though, and the API is extremely minimal, just the bare minumum
to make ZeroMQ work with EventMachine.

## Using: ##

You must use either rubinius, jruby, or 1.9.x. 1.8.7 does not work with libzmq.

If you use 1.9.x, be sure to install the ffi gem first.

For all rubies install ffi-rzmq and eventmachine as well.

This only works with ZeroMQ 2.1.x which is still unreleased
Build+Install ZeroMQ 2.1 from HEAD ( https://github.com/zeromq/zeromq2 ) 

Run the specs, see specs for examples

Want to help out? Ask!

## Example ##
    require 'rubygems'
    require 'em-zeromq'
        
    Thread.abort_on_exception = true

    class EMTestPullHandler
      attr_reader :received
      def on_readable(socket, messages)
        messages.each do |m|
          puts m.copy_out_string
        end
      end
    end

    EM.run do
      ctx = EM::ZeroMQ::Context.new(1)
      
      # setup push sockets
      push_socket1 = ctx.bind( ZMQ::PUSH, 'tcp://127.0.0.1:2091')
      push_socket2 = ctx.bind( ZMQ::PUSH, 'ipc:///tmp/a')
      push_socket3 = ctx.bind( ZMQ::PUSH, 'inproc://simple_test')
      
      # setup one pull sockets listening to both push sockets
      pull_socket = ctx.connect( ZMQ::PULL, 'tcp://127.0.0.1:2091', EMTestPullHandler.new)
      pull_socket.connect('ipc:///tmp/a')
      pull_socket.connect('inproc://simple_test')
      
      n = 0
      
      # push_socket.hwm = 40
      # puts push_socket.hwm
      # puts pull_socket.hwm
      
      EM::PeriodicTimer.new(0.1) do
        puts '.'
        push_socket1.send_msg("t#{n += 1}_")
        push_socket2.send_msg("i#{n += 1}_")
        push_socket3.send_msg("p#{n += 1}_")
      end
    end

## License: ##

(The MIT License)

Copyright (c) 2011

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
