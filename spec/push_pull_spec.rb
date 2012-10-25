require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  it "Should instantiate a connection given valid opts" do
    pull_conn = nil
    run_reactor do
      pull_conn = SPEC_CTX.socket(ZMQ::PULL)
      pull_conn.bind(rand_addr)
    end
    pull_conn.should be_a(EventMachine::ZeroMQ::Socket)
  end

  describe "sending/receiving a single message via PUB/SUB" do
    before(:all) do
      @results = {}
      @received = []
      @test_message = test_message = "TMsg#{rand(999)}"
      
      run_reactor(0.2) do
        address = rand_addr
        
        pull_conn = SPEC_CTX.socket(ZMQ::PULL)
        pull_conn.bind(address)
        pull_conn.on(:message) { |m|
          @received << m
        }
        
        push_conn  = SPEC_CTX.socket(ZMQ::PUSH)
        push_conn.connect(address)
        
        push_conn.socket.send_string test_message, ZMQ::NOBLOCK
        
        EM::Timer.new(0.1) { @results[:specs_ran] = true }
      end
    end

    it "should run completely" do
      @results[:specs_ran].should be_true
    end
    
    it "should receive the message intact" do
      @received.should_not be_empty
      @received.first.should be_a(ZMQ::Message)
      @received.first.copy_out_string.should == @test_message
    end
  end
end
