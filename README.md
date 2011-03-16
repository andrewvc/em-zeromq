# em-zeromq #

## Description: ##

EventMachine support for ZeroMQ

## Usage: ##

Tested and functional with Rubinius, jRuby, and 1.9.2.

If using 1.9.2 you must `gem install ffi` before using.

MRI 1.8.7 does not work with libzmq.

This only works with ZeroMQ 2.1.x which is still unreleased
Build+Install ZeroMQ 2.1 from HEAD ( https://github.com/zeromq/zeromq2 ) 

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
