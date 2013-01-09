require File.join(File.dirname(__FILE__), %w[spec_helper])

describe 'Socket' do
  before do
    @ctx = EM::ZeroMQ::Context.new(1)
  end

  it 'can create a socket' do
    EM.run do
      s = @ctx.socket(ZMQ::ROUTER)
      s.instance_variable_get('@socket').name.should == 'ROUTER'
      EM.stop
    end
  end

  it 'can set hwm' do
    EM.run do
      s = @ctx.socket(ZMQ::PUSH)
      s.hwm = 100
      if defined?(ZMQ::HWM)
        s.hwm.should == 100
      else
        s.rcvhwm.should == 100
        s.sndhwm.should == 100
      end
      EM.stop
    end
  end
end
