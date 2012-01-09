require './helpers.rb'

module ArduinoGateway

  class RestfulRequest
      include ArduinoGateway::Helpers

      attr_accessor :id, :method_type, :address, :body
      attr_reader :resources_list, :resources, :options
   
      # initilize method called to create a new message object   
      def initialize(id="-1", request="", _address={:ip => "0.0.0.0", :port => -1})
        @debug_code = true

        @address = {}
        @resources_list = []
        @options = {}
        @id = id
        @body = ""
        @method_type = ""
        @address[:ip] = _address[:ip] if _address[:ip]
        @address[:port] = _address[:port] if _address[:port]

        get_request_syntax = /(GET|POST) (\/\S*)(?:[ ]*(.*$)\n){0,1}((?:^\S*: *.*$\n)*)(?:\n*(^[\w|\=|\&]*$)\n*)*/ 
        if client_get_request_match = get_request_syntax.match(request)
            self.method_type = $1 if $1
            self.resources = $2 if $2
            self.options = $4 if $4
            self.body = $5 if $5
            puts "[RestfulRequests:initialize] all matches: #{p client_get_request_match}"
            puts "[RestfulRequests:initialize] request initialized #{self.full_request}"
          else; puts "[RestfulRequests:initialize] ERROR RESCUE: request could not be initialized" 
        end

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
      # return_string = "#{@method_type.upcase} #{@resources}\r\n\r\n"
      return_string = "#{@method_type.upcase} #{@resources}\r\n"
    end

    def full_request
     return "#{self.restful_request} #{self.http_address}, #{@options}, #{@body}"
    end

  end # RestfulRequest class

end # ArduinoGateway module