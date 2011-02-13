require File.join(File.dirname(__FILE__), %w[spec_helper])

describe EventMachine::ZeroMQ do
  class EMTestXREQHandler
    attr_reader :received
    def initialize
      @received = []
    end
    def on_readable(socket, messages)
      @received += messages
    end
  end
  class EMTestXREPHandler
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
    xreq_conn = nil
    run_reactor(1) do
      xreq_conn = SPEC_CTX.bind(ZMQ::XREQ, rand_addr, EMTestXREQHandler.new)
    end
    xreq_conn.should be_a(EventMachine::ZeroMQ::Connection)
  end

  describe "sending/receiving a single message via Xreq/Xrep" do
    before(:all) do
      results = {}
      @test_message = test_message = "M#{rand(999)}"
      
      run_reactor(0.5) do
        results[:xrep_hndlr] = xrep_hndlr = EMTestXREPHandler.new
        results[:xreq_hndlr] = xreq_hndlr = EMTestXREQHandler.new
        xreq_conn = SPEC_CTX.connect(ZMQ::XREQ, rand_addr, xreq_hndlr, :identity => "req1")
        xreq_conn.send_msg('', test_message)
        
        xrep_conn = SPEC_CTX.bind(ZMQ::XREP, xreq_conn.address, xrep_hndlr, :identity => "rep1")
         
        EM::Timer.new(0.1) do
          results[:specs_ran] = true
        end
      end
      
      @results = results
    end

    it "should run completely" do
      @results[:specs_ran].should be_true
    end
    
    it "should receive the message intact on the xrep" do
      @results[:xrep_hndlr].received.should_not be_empty
      @results[:xrep_hndlr].received.last.should be_a(ZMQ::Message)
      @results[:xrep_hndlr].received.last.copy_out_string.should == @test_message
    end

    it "the xreq should be echoed its original message" do
      @results[:xreq_hndlr].received.should_not be_empty
      @results[:xreq_hndlr].received.last.should be_a(ZMQ::Message)
      @results[:xreq_hndlr].received.last.copy_out_string.should == "re:#{@test_message}"
    end
  end
end
