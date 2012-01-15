module ArduinoGateway
  
  module Helpers

    # ADDRESS_VALID?
    # checks address validity by confirming data type, and presence of ip and port key
    def address_valid?(address)
        if address[:ip].to_s.match(/\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/) and address[:port].to_s.match(/\d{3,6}/)
          return true
        elsif address[:ip].to_s.match(/tty.usb\S*/) and address[:port].to_s.match(/0/)
          return true
        end
    end  

    def error_msg(error_type, exception_msg = nil)
      custom_msg = "An issue was encountered when trying to process the current request"
      if error_type == :arduino_address
        custom_msg = "Not able to connect to the arduino because of issue with address or port number."
      elsif error_type == :timeout
        custom_msg = "The connection to the arduino timed out because no response was received."
      elsif error_type == :request_not_supported
        custom_msg = "Current request cannot be handled; system only supports GET and POST requests."
      end       
      custom_msg = " #{custom_msg}; SYSTEM msg: #{exception_msg}" if !exception_msg.nil?
      "ERROR msg: #{custom_msg}; TIME: #{Time.now}"
    end 
    
    def keys_to_string(new_record)
      new_record = new_record.inject({}) do |new_hash,(k,v)| 
        new_hash[k.to_s] = v
        new_hash
      end        
    end
    
    class Timer
      class << self
        def get(timeout)
          return unless block_given?
          timer_thread = Thread.new(timeout) do |timeout_time|
            start_time = Time.now.to_i
            end_time = start_time + timeout_time

            puts "[get_new_timer] timer started from #{start_time} to #{end_time}"        
            loop do
              current_time = Time.now.to_i
              if current_time > end_time
                yield 
                puts "[get get_new_timer] timer completed at #{current_time}"
                self.terminate
              end
            end
          end
          timer_thread
        end
      end
    end
    
  end

end