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
      
      def initialize()
        @timers = []
        @timer_thread = Thread.new() do
          puts "[Timer:initialize] Timer thread started at #{Time.now.to_i}"
          loop do
            current_time = Time.now.to_i
            @timers.select! do | timer |
              # check if any of the timers have timed out, if so call code block
              if current_time > timer[:end_time]
                begin
                  timer[:block].call
                  puts "[Timer:instance_thread] timer completed at #{Time.now.to_i}"
                rescue => e
                  timer[:block] = ""
                  puts "[Timer:instance_thread] error calling code block associated to end time #{timer[:end_time]}"
                end
              end
              # check if current item should be removed from @timers array 
              !(current_time > timer[:end_time]) 
            end # @timers.select! iterator
          end # loop block          
        end # @timer thread
      end # initialize method
      
      def new_timer(timeout, &timeout_block)
        end_time = Time.now.to_i + timeout
        @timers.push({end_time: end_time, block: timeout_block})
        puts "[Timer:set_timeout] set_new timer with end time at #{end_time}, #{@timers.size}"
      end # set_timeout method
      
    end # Timer class
    
  end

end