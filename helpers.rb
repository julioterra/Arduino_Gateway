module ArduinoGateway
  
  module Helpers

    # ADDRESS_VALID?
    # checks address validity by confirming data type, and presence of ip and port key
    def address_valid?(address)
        address[:ip].to_s.match(/\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/) and address[:port].to_s.match(/\d{3,6}/)
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
    
  end

end