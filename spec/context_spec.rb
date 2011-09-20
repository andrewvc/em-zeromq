require File.join(File.dirname(__FILE__), %w[spec_helper])

describe 'Context' do
  before do
    @ctx = EM::ZeroMQ::Context.new(1)
  end
  
  it 'can be created with a context' do
    zmq_ctx = ZMQ::Context.new(1)
    ctx = EM::ZeroMQ::Context.new( zmq_ctx )
    ctx.instance_variable_get('@context').should == zmq_ctx
  end
  
  it 'can create socket' do
    EM::run do
      s1 = @ctx.bind(:router, 'tcp://127.0.0.1:5555')
      s2 = @ctx.bind('router', 'tcp://127.0.0.1:5556')
      s3 = @ctx.bind(ZMQ::ROUTER, 'tcp://127.0.0.1:5557')
    
      s1.instance_variable_get('@socket').name.should == 'ROUTER'
      EM::stop_event_loop
    end
  end
end

