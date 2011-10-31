module RZMQCompat
  class ZMQError < RuntimeError; end
  class ZMQOperationFailed < ZMQError; end
  
  def self.included(klass)
    klass.instance_eval do
      %w(getsockopt recv).each do |m|
        alias_method :"#{m}_without_raise", m.to_sym
        alias_method m.to_sym, :"#{m}_with_raise"
      end
    end
  end
  
  def getsockopt_with_raise(opt, *args)
    arity = method(:getsockopt_without_raise).arity
    if args.empty?
      case arity
      when 1
        getsockopt_without_raise(opt)
        
      when 2
        ret = []
        rc = getsockopt_without_raise(opt, ret)
        unless ZMQ::Util.resultcode_ok?(rc)
          raise ZMQOperationFailed, "getsockopt: #{ZMQ.errno}"
        end
    
        (ret.size == 1) ? ret[0] : ret
  
      else
        raise "Unsupported version of ffi-rzmq, getsockopt takes #{arity} arguments"
      end
    
    else
      # just pass the call to the original method  
      getsockopt_without_raise(opt, *args)
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
