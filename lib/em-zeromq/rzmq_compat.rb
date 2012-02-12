module RZMQCompat
  class ZMQError < RuntimeError; end
  class ZMQOperationFailed < ZMQError; end
  
  def self.included(klass)
    klass.instance_eval do
      %w(recv).each do |m|
        alias_method :"#{m}_without_raise", m.to_sym
        alias_method m.to_sym, :"#{m}_with_raise"
      end
    end
  end
  
  def recv_with_raise(msg, flags = 0)
    ret = recv_without_raise(msg, flags)
    if (ret == true) || (ret == 0)
      true
    else
      false
    end
  end
  
  
end

ZMQ::Socket.send(:include, RZMQCompat)
