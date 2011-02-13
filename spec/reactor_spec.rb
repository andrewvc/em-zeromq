require File.join(File.dirname(__FILE__), %w[spec_helper])

describe 'Reactor' do
  before do
    @reactor = EM::ZeroMQ::Reactor.new(1)
  end
  
  it 'can be created with a context' do
    ctx = ZMQ::Context.new(1)
    reactor = EM::ZeroMQ::Reactor.new( ctx )
    reactor.instance_variable_get('@context').should == ctx
  end
  
  it 'can create socket' do
    EM::run do
      s1 = @reactor.bind(:xreq, 'tcp://127.0.0.1:5555')
      s2 = @reactor.bind('xreq', 'tcp://127.0.0.1:5556')
      s3 = @reactor.bind(ZMQ::XREQ, 'tcp://127.0.0.1:5557')
    
      s1.instance_variable_get('@socket').name.should == 'XREQ'
      EM::stop_event_loop
    end
  end
end

