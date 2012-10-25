require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  it "Should instantiate a connection given valid opts" do
    sub_conn = nil
    address = rand_addr
    
    run_reactor do
      sub_conn = SPEC_CTX.socket(ZMQ::PUB)
      sub_conn.bind(address)
    end
    sub_conn.should be_a(EventMachine::ZeroMQ::Socket)
  end

  describe "sending/receiving a single message via PUB/SUB" do
    before(:all) do
      @results = {}
      @received = []
      @test_message = test_message = "TMsg#{rand(999)}"
      
      run_reactor do
        address = rand_addr
        
        sub_conn  = SPEC_CTX.socket(ZMQ::SUB)
        sub_conn.bind(address)
        sub_conn.subscribe('')
        sub_conn.on(:message) { |m|
          @received << m
        }
        
        pub_conn  = SPEC_CTX.socket(ZMQ::PUB)
        pub_conn.connect(address)
        
        pub_conn.socket.send_string test_message, ZMQ::NOBLOCK
        
        EM::Timer.new(0.1) { @results[:specs_ran] = true }
      end
    end
  
    it "should run completely" do
      @received.should be_true
    end
    
    it "should receive one message" do
      @received.length.should == 1
    end
    
    it "should receive the message as a ZMQ::Message" do
      @received.first.should be_a(ZMQ::Message)
    end
    
    it "should receive the message intact" do
      @received.first.copy_out_string.should == @test_message
    end
  end
end
