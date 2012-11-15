# em-zeromq #

## Current maintainer ##

This gem is currently maintained by schmurfy, it will stay here for now
but may be moved to my account later.

## Description: ##

EventMachine support for ZeroMQ

## Usage: ##

Supported on:

- MRI 1.9+
- Rubinius
- JRuby

While the gem should work on Rubinius and JRuby I mainly use it with MRI 1.9+ so
there may be some glitchs.

Want to help out? Ask!

## Usage Warning ##

To ensure your zeromq context won't be reclaimed by the garbage collector you need
to keep a reference to it in scope, this is what you don't want to do (that's how the example used to be written):

```ruby
EM.run do
  context = EM::ZeroMQ::Context.new(1)
  dealer_socket = context.socket(...)
  dealer_socket.connect(...)
  dealer_socket.send_msg('', "ping")
end
```

If you do this everything will appear to work fine at first but as soon as the garbage collector
is triggered your context will get destroyed and your application will hang.

The same may be true for references to socket but I have no evidence of that.  
It should not be a major problem anyway since code like above is only written for examples/tests
but I just pulled my hair trying to figure out why my test code was not working so now you
have been warned !

## Breaking changes: 0.2.x => 0.3.x ##

Until the gem hit the 1.0 mark you should not use the "~>" operator in your Gemfile,
lock yourself to the exact version you want. That said I will use the second digit to
flag api changes but be aware that small changes can still occur between releases.


## Example ##
```ruby
require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  push = zmq.socket(ZMQ::PUSH)
  push.connect("tcp://127.0.0.1:2091")

  pull = zmq.socket(ZMQ::PULL)
  pull.bind("tcp://127.0.0.1:2091")

  pull.on(:message) { |part|
    puts part.copy_out_string
  }

  EM.add_periodic_timer(1) {
    push.send_msg("Hello")
  }
}
```

## License: ##

(The MIT License)

Copyright (c) 2011 - 2012

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
