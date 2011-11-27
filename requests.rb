module ArduinoGateway

  class RestfulRequest
      attr_accessor :id, :method_type, :address
      attr_reader :resources_list, :resources, :options
   
      # initilize method called to create a new message object   
      def initialize(id="", request="", address={:ip => "0.0.0.0", :port => -1})
        @debug_code = true

        self.id = id
        self.address = address

        get_request_syntax = /(?:(GET|POST) (\/.*?) (.*$)\n)((?:^\S*: .*$\n)*)/	
        if client_get_request_match = get_request_syntax.match(request)
          self.method_type = $1 if $1
          self.resources = $2 if $2
          self.options = $4 if $4
        else puts "[RestfulRequests:initialize] ERROR RESCUE: request could not be initialized" 
        end

        puts "[RestfulRequests:initialize] new request initialized:",
             "method: #{@method_type}, \nresources: #{@resources}", 
             "options: #{@options}, \naddress: #{@address}"
      end
   

     # RESOURCES=
     def resources=(resources_in)
       @resources_list = []
       if resources_in.is_a? String
         @resources = resources_in
         @resources_list = resources_in.split("/").select { |resource| !resource.empty? }
       elsif resources_in.is_a? Array
         @resources_list = resources_in.select { |resource| !resource.empty? }
         @resources = @resource_list.join('/')
       end
       @resources_list
       rescue => e
         puts "[RestfulRequests:resources=] ERROR RESCUE: #{e.message}"
         @resources_list            
     end
    
    
    # OPTIONS=
    def options=(option_in)
      @options = {}
      if option_in.is_a? String
        option_in.split("\r\n").each do |data|
          if data.include?(":")
            data.match(/^([^:\r\n]+): ?([^\r\n]+)$/)
            @options.merge!({$1 => $2})
          end
        end
      elsif option_in.is_a? Hash
        @options = option_in
      else; puts "[RestfulRequests:options=] ERROR RESCUE: options could not be parsed"          
      end        
    end
    
    
    def http_address
       return "http://#{@address[:ip].to_s}:#{@address[:port].to_s}"
    end

    def restful_request
     return_string = "#{@method_type.upcase} #{@resources}\r\n\r\n"
    end

    def full_request
     return_string = "#{self.full_address} #{@method_type.upcase} #{@resources}\r\n\r\n"
    end


  end

end