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
      @received += [ident, delim, message].map {|s| ZMQ::Message.new(s)}
      socket.send_string ident, ZMQ::SNDMORE
      socket.send_string delim, ZMQ::SNDMORE
      socket.send_string message
    end
  end

  def make_xreq(addr, b_or_c, handler=EMTestXREQHandler.new)
    conn = EM::ZeroMQ.create SPEC_CTX, ZMQ::XREQ, b_or_c, addr, handler
    conn.register_readable
    conn
  end
  
  def make_xrep(addr, b_or_c, handler=EMTestXREPHandler.new)
    conn = EM::ZeroMQ.create SPEC_CTX, ZMQ::XREP, b_or_c, addr, handler
    conn.register_readable
    conn
  end

  it "Should instantiate a connection given valid opts" do
    xreq_conn = nil
    run_reactor(1) do
      xreq_conn = make_xreq(rand_addr, :bind, EMTestXREQHandler.new)
    end
    xreq_conn.should be_a(EventMachine::ZeroMQ::Connection)
  end

  describe "sending/receiving a single message via Xreq/Xrep" do
    before(:all) do
      results = {}
      @test_message = test_message = "TMsg#{rand(999)}"
      
      run_reactor(1.5) do
        results[:xrep_hndlr] = xrep_hndlr = EMTestXREPHandler.new
        results[:xreq_hndlr] = xreq_hndlr = EMTestXREQHandler.new
        xreq_conn  = make_xreq rand_addr,         :connect,    xreq_hndlr
        xrep_conn  = make_xrep xreq_conn.address, :bind, xrep_hndlr
         
        xreq_conn.socket.send_string '', ZMQ::SNDMORE #delim
        xreq_conn.socket.send_string test_message
         
        EM::Timer.new(0.1) { results[:specs_ran] = true }
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
      @results[:xreq_hndlr].received.last.copy_out_string.should == @test_message
    end
  end
end
