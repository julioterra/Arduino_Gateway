
class RestfulRequest
   attr_accessor :method_type, :format, :options, :address, :id
   attr_reader :resources_list, :resources
   
   def initialize(id="", method="", resources="", format="", address={:ip_host => "0.0.0.0", :port => -1})
      puts "[RestfulRequests:initialize] initializing server request object"
        @id = id
        @method_type = method
        @format = format
        @resources = resources
        @address = address
        @options = {}
        self.resources_list = @resources
        puts "[RestfulRequests:initialize] finished initializing, - num of resource: #{@resource_list.length}"
        # puts "[RestfulRequests:initialize] finished initializing, - num of resource: #{@address}"
        # self.print
   end
   
   
   def resources=(resources_in)
     # user resource_list= method to assign the resouce_list and resource variable
     #    this method is able to handle both array and string input
     self.resource_list = @resources
   end

   def full_address
      return "http://" + @address[:ip_host].to_s + ":" + @address[:port].to_s 
   end

   ##########
   # change to hash
   def options=(*option_in)
        if (option_in.kind_of? String)
            @option = option_in
         elsif ((option_in.kind_of? Array) || (option_in.kind_of? Hash))
            @option = option_in.join ", "
       end
   end

   # Resource List = 
   # method can take input that is an array or string. It converts the input as needed
   def resources_list=(resource_in)
     debug_code = false
     if debug_code ; puts "[RestfulRequests:resource_list:0] creating a resource object: #{resource_in}"; end

     #handle string input
     if (resource_in.kind_of? String)
         # create a list of resources (disregard first position, which is blank) 
         # then reformat each entry to include a starting forward slash
         # lastly, add an ending forward slash, if appropriate
         if debug_code ; puts "[RestfulRequests:resource_list:1] string input" ; end
         @resource = resource_in
         @resource_list = @resource[1..-1].split('/')   
         @resource_list = @resource_list.map {|resource| resource = '/' + resource } 
         if resource_in.chomp.end_with?('/') ; @resource_list << '/' ; end
         if debug_code ; puts "[RestfulRequests:resource_list:2] string converted : #{@resource_list}"; end

      #handle array input
      elsif (resource_in.kind_of? Array)
          # go through each element in the input array using map function
          # make sure all elements start with a forward slash before saving
          if debug_code ; puts "[RestfulRequests:resource_list:3] array input"; end
          resource_list_update_with_array = resource_in
      end
      @resource_list
      rescue => e
        puts "[RestfulRequests:resource_list] RESCUE: #{e.message}", e.backtrace
        @resource_list      
  end ## END :resources_list
  

    def resource_list_array=(resource_in)
        if (resource_in.kind_of? Array)
            @resource_list = resource_in.map { |resource| 
              if !resource.chomp.start_with?('/') ; resource = '/' + resource ; end
            } 
            @resources = @resource_list.join
        end
    end
    
   def print
     puts "[RestfulRequests:print] resftul request: #{self.restful_request}"
     puts "[RestfulRequests:print] full request: #{self.full_request}"
     puts "[RestfulRequests:print] address: #{self.full_address}"
     
     recompiled_resource = @method_type.upcase + " " + @resource_list.join + " " + @format
     puts "[RestfulRequests:print] request recompiled: #{recompiled_resource}"
   end

   def restful_request
     return_string = @method_type.upcase + " " + @resources + " " + @format + "\r\n\r\n"
     # puts "[RestfulRequests:get_request] RESTful request: #{return_string}"
     return_string
   end

   def full_request
     return_string = @address[:ip_host].to_s + " " + @address[:port].to_s + " " + 
                     @method_type.upcase + " " + @resources + " " + @format + "\r\n\r\n"
     # puts "[RestfulRequests:full_request] FULL request: #{return_string}"
   end


end
