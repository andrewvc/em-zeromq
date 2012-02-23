require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  class EMTestRouterHandler
    attr_reader :received
    def initialize
      @received = []
    end
    def on_writable(socket)
    end
    def on_readable(socket, messages)
      @received += messages
    end
  end

  class EMTestDealerHandler
    attr_reader :received
    def initialize(&block)
      @received = []
      @on_writable_callback = block
    end
    def on_writable(socket)
      @on_writable_callback.call(socket) if @on_writable_callback
    end
    def on_readable(socket, messages)
      _, message = messages.map(&:copy_out_string)
      @received += [message].map {|s| ZMQ::Message.new(s)}
      
      socket.send_msg('', "re:#{message}")
    end
  end

  it "Should instantiate a connection given valid opts for Router/Dealer" do
    router_conn = nil
    run_reactor(1) do
      router_conn = SPEC_CTX.bind(ZMQ::ROUTER, rand_addr, EMTestRouterHandler.new)
    end
    router_conn.should be_a(EventMachine::ZeroMQ::Connection)
  end

  describe "sending/receiving a single message via Router/Dealer" do
    before(:all) do
      results = {}
      @test_message = test_message = "M#{rand(999)}"
      
      run_reactor(2) do
        results[:dealer_hndlr] = dealer_hndlr = EMTestDealerHandler.new
        results[:router_hndlr] = router_hndlr = EMTestRouterHandler.new

        addr = rand_addr
        dealer_conn = SPEC_CTX.bind(ZMQ::DEALER, addr, dealer_hndlr, :identity => "dealer1")
        router_conn = SPEC_CTX.connect(ZMQ::ROUTER, addr, router_hndlr, :identity => "router1")
        
        EM::add_timer(0.1) do
          router_conn.send_msg('dealer1','', test_message)
        end
         
        EM::Timer.new(0.2) do
          results[:specs_ran] = true
        end
      end
      
      @results = results
    end

    it "should run completely" do
      @results[:specs_ran].should be_true
    end
    
    it "should receive the message intact on the dealer" do
      @results[:dealer_hndlr].received.should_not be_empty
      @results[:dealer_hndlr].received.last.should be_a(ZMQ::Message)
      @results[:dealer_hndlr].received.last.copy_out_string.should == @test_message
    end

    it "the router should be echoed its original message" do
      @results[:router_hndlr].received.should_not be_empty
      @results[:router_hndlr].received.last.should be_a(ZMQ::Message)
      @results[:router_hndlr].received.last.copy_out_string.should == "re:#{@test_message}"
    end
  end
end
