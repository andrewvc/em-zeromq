require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  class EMTestROUTERHandler
    attr_reader :received
    def initialize
      @received = []
    end
    def on_readable(socket, messages)
      @received += messages
    end
  end

  class EMTestDEALERHandler
    attr_reader :received
    def initialize(&block)
      @received = []
      @on_writable_callback = block
    end
    def on_writable(socket)
      @on_writable_callback.call(socket) if @on_writable_callback
    end
    def on_readable(socket, messages)
      ident, delim, message = messages.map(&:copy_out_string)
      ident.should == "req1"
      @received += [ident, delim, message].map {|s| ZMQ::Message.new(s)}
      
      socket.send_msg(ident, delim, "re:#{message}")
    end
  end

  it "Should instantiate a connection given valid opts" do
    router_conn = nil
    run_reactor(1) do
      router_conn = SPEC_CTX.bind(ZMQ::ROUTER, rand_addr, EMTestROUTERHandler.new)
    end
    router_conn.should be_a(EventMachine::ZeroMQ::Connection)
  end

  describe "sending/receiving a single message via Xreq/Xrep" do
    before(:all) do
      results = {}
      @test_message = test_message = "M#{rand(999)}"
      
      run_reactor(0.5) do
        results[:dealer_hndlr] = dealer_hndlr = EMTestDEALERHandler.new
        results[:router_hndlr] = router_hndlr = EMTestROUTERHandler.new
        router_conn = SPEC_CTX.connect(ZMQ::ROUTER, rand_addr, router_hndlr, :identity => "req1")
        router_conn.send_msg('', test_message)
        
        dealer_conn = SPEC_CTX.bind(ZMQ::DEALER, router_conn.address, dealer_hndlr, :identity => "rep1")
         
        EM::Timer.new(0.1) do
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
