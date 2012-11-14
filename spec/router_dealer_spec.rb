require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  it "Should instantiate a connection given valid opts for Router/Dealer" do
    router_conn = nil
    run_reactor do
      router_conn = SPEC_CTX.socket(ZMQ::ROUTER)
      router_conn.bind(rand_addr)
    end
    router_conn.should be_a(EventMachine::ZeroMQ::Socket)
  end

  describe "sending/receiving a single message via Router/Dealer" do
    before(:all) do
      @results = {}
      @dealer_received, @router_received = [], []
      @test_message = test_message = "M#{rand(999)}"
      
      run_reactor(0.3) do
        addr = rand_addr
        dealer_conn = SPEC_CTX.socket(ZMQ::DEALER)
        dealer_conn.identity = "dealer1"
        dealer_conn.bind(addr)
        dealer_conn.on(:message) { |message|
          # 2. Dealer receives messages, sends reply back to router
          @dealer_received << message
          dealer_conn.send_msg("re:#{message.copy_out_string}")
        }
        
        router_conn = SPEC_CTX.socket(ZMQ::ROUTER)
        router_conn.identity = "router1"
        router_conn.connect(addr)
        router_conn.on(:message) { |*parts|
          # 3. Message received in router identifies the sending dealer
          @router_received << parts
        }
        
        EM::add_timer(0.1) do
          # 1. Send message to the dealer
          router_conn.send_msg('dealer1', test_message)
        end
         
        EM::Timer.new(0.2) do
          @results[:specs_ran] = true
        end
      end
    end

    it "should run completely" do
      @results[:specs_ran].should be_true
    end
    
    it "should receive the message intact on the dealer" do
      @dealer_received.should_not be_empty
      @dealer_received.last.should be_a(ZMQ::Message)
      @dealer_received.last.copy_out_string.should == @test_message
    end

    it "the router should be echoed its original message with the dealer identity" do
      @router_received.size.should == 1
      parts = @router_received[0]
      parts[0].copy_out_string.should == "dealer1"
      parts[1].copy_out_string.should == "re:#{@test_message}"
    end
  end
end
