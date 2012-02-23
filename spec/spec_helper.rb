require 'rspec'
require 'set'
Thread.abort_on_exception = true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib em-zeromq]))

def run_reactor(time=0.2,&block)
  Thread.new do
    EM.run do
      yield
    end
  end
  sleep time
  EM.stop rescue nil
  sleep 0.1
end

USED_RAND_ADDRS = Set.new
def rand_addr(scheme='tcp')
  addr = nil
  loop do 
    case scheme
    when 'tcp'
      addr = "tcp://127.0.0.1:#{rand(10_000) + 20_000}"
    when 'inproc'
      addr = "inproc://testinp-#{rand(10_000) + 20_000}"
    end
    
    if USED_RAND_ADDRS.include? addr
      next
    else
      USED_RAND_ADDRS << addr
      break
    end
  end
  addr
end

SPEC_CTX = EM::ZeroMQ::Context.new(1)
def spec_ctx
  SPEC_CTX
end
