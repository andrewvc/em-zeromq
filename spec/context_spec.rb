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
      s = @ctx.socket(ZMQ::ROUTER)
      s.instance_variable_get('@socket').name.should == 'ROUTER'
      EM::stop_event_loop
    end
  end
end

