module ArduinoGateway

  class RestfulRequest
      attr_accessor :id, :method_type, :options, :address
      attr_reader :resources_list, :resources
   
      # initilize method called to create a new message object   
      def initialize(id="", request="", address={:ip => "0.0.0.0", :port => -1})
          @debug_code = true

          @id = id

          get_request_syntax = /(?:(GET|POST) (\/.*?) (.*$)\n)((?:^\S*: .*$\n)*)/	
          client_get_request_match = get_request_syntax.match(request)
          self.method_type = $1
          self.resources = $2
          self.options = $3

          @address = address
          puts "[RestfulRequests:initialize] initialized server request, method: #{@method_type}, resources: #{@resources}"
      end
   
     def resources=(resources_in)
       # using resource_list= method to assign the resouce_list and resource variable
       # because this method is able to handle both array and string input
       self.resources_list = resources_in
     end

    # method can take input that is an array or string and converts in order to 
    # assign the proper values for the @resource and @resource_list variables.
    def resources_list=(resource_in)
        if resource_in.is_a? String
            @resources = resource_in
            @resources_list = resource_in.split("/").select { |resource| !resource.empty? }
        elsif resource_in.is_a? Array
            @resources_list = resource_in.select { |resource| !resource.empty? }
            @resources = @resource_list.join('/')
        end
        @resources_list
        rescue => e
            puts "[RestfulRequests:resource_list] RESCUE: #{e.message}", e.backtrace
            @resources_list            
    end

    
    # accepts a string, array or hash to be used for setting the 
    # @options hash
    def options=(*option_in)
        @options = to_hash(option_in)
    end
  
    # converts strings and arrays to hashs. Assumes that text is provided
    # using following conventions: key/value pairs should be divivded by ","
    # while keys are divided from values by ":".
    def to_hash(*new_data)
        new_hash = {}
      
        # if new_data variable is a string then convert it into an array
        # each item is separated by a ",", and whitespace is removed
        if new_data.is_a? String 
           new_data = new_data.split(",").chomp    
        end    
      
        # if new_data variable is an array then convert it into a hash
        # make sure that array is not empty, then process the data
        if new_data.is_a? Array
            return new_hash if new_data.empty?

            # if array has more than 1 element then convert into a hash
            # check whether each array element contains a key/value pair
            # then create a hash with the arrays contents
            new_data.map! do |data| data = data.to_s end
            new_data.select! do |data| data.include?(":") || data.include?("=>") end
            new_data.map! do |data| 
                if data.include?("{") || data.include?("}") then data.gsub!(/ ?{|}/,"") end
                if data.include?(":") & data.include?("=>") then data = data.split("=>") 
                else data = data.split(/\=\> ?|\: ?/) end
                new_hash[data[0]] = data[1]
            end

            # if array has only one element then check whether it is a
            # hash list. If so, assign the hash to the new_data variable
            if new_data[0].is_a? Hash
                new_data = new_data[0] 
            end
        end

        # if new_data variable is a hash then assign it to the new_hash
        # variable that will be returned by this method
        if (new_data.is_a? Hash)
            new_hash = new_data
        end
        new_hash
    end
    
    def print
       puts "[RestfulRequests:print] resftul request: #{self.restful_request}"
       puts "[RestfulRequests:print] full request: #{self.full_request}" 
    end

    def full_address
       return "http://#{@address[:ip].to_s}:#{@address[:port].to_s}"
    end

    def restful_request
     return_string = "#{@method_type.upcase} #{@resources}\r\n\r\n"
     puts "[RestfulRequests:restful_request] #{return_string}"
     return_string
    end

    def full_request
     return_string = self.full_address + " " +  @method_type.upcase + " " + 
                     @resources + "\r\n\r\n"
    end


  end

end