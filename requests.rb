
class RestfulRequest
   attr_accessor :method_type, :format, :options, :address, :id
   attr_reader :resources_list, :resources
   
   # initilize method called to create a new message object
   # the port number in the address hash is set to -1. Here is a table
   # that explains the port value meaning:
   #      (1) greater than 0: these port numbers refer to actual addresses 
   #          and so if the port number is greater than 0 than address can 
   #          considered to be SET
   #      (2) -1: port address has not been set yet
   #      (3) -11: request should be ignored without raising exceptions or redirecting
   #      (3) -12: request return an exception in the form of a missing resource page
   
   def initialize(id="", method="", resources="", format="", address={:ip => "0.0.0.0", :port => -1})
      puts "[RestfulRequests:initialize] initializing server request object"
        @id = id
        @method_type = method
        @format = format
        @resources = resources
        @address = address
        @options = {}
        self.resources_list = @resources
        puts "[RestfulRequests:initialize] finished initializing, - num of resource: #{@resource_list.length}"
   end
   
   def resources=(resources_in)
     # using resource_list= method to assign the resouce_list and resource variable
     # because this method is able to handle both array and string input
     self.resource_list = @resources
   end

   # method can take input that is an array or string and converts in order to 
   # assign the proper values for the @resource and @resource_list variables.
   def resources_list=(resource_in)
     debug_code = false
     if debug_code ; puts "[RestfulRequests:resource_list:0] creating a resource object: #{resource_in}"; end

     #handle string input
     if (resource_in.kind_of? String)
         # create a list of resources (disregard first position, which is blank) 
         # then reformat each entry to include a starting forward slash
         # lastly, add an ending forward slash, if appropriate
         @resource = resource_in
         @resource_list = clean_resource_array(@resource.split('/'))
         if debug_code ; puts "[RestfulRequests:resource_list:2] string input : #{@resource_list}"; end

      #handle array input
      elsif (resource_in.kind_of? Array)
          # go through each element in the input array using map function
          # make sure all elements start with a forward slash before saving
          @resource_list = clean_resource_array(resource_in)
          @resources = @resource_list.join
          if debug_code ; puts "[RestfulRequests:resource_list:3] array input : #{@resource_list}"; end
      end
      @resource_list
      rescue => e
        puts "[RestfulRequests:resource_list] RESCUE: #{e.message}", e.backtrace
        @resource_list            
  end ## END :resources_list
  
  def clean_resource_array(resource_in)
      # remove any empty resources from the array.
      resource_in = resource_in.select do |resource|
          !resource.empty?
      end
      
      # add a "/" to the start of each element in the array
      resource_clean = resource_in.map do |resource| 
          if !resource.chomp.start_with?('/') ; resource = '/' + resource ; end
      end
      
      # add a "/" element to the end of the array if the last element ended 
      # with this character
      if resource_clean.last.to_s.end_with?('/')
          resource_clean << '/' 
      end
      
      # check all but the last element in the array to make sure that they
      # do not end with a "/"
      resource_clean[0..-2].each do |resource| 
          if !resource.chomp.ends_with?('/') ; resource = resource[0..-2] ; end
      end

      resource_clean
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
      if (new_data.kind_of? String)
         new_data = new_data.split(",").chomp    
      end    
      
      # if new_data variable is an array then convert it into a hash
      # make sure that array is not empty, then process the data
      if (new_data.is_a? Array)

          # return an empty hash if the new_data array is empty
          return new_hash if new_data.empty?

          # if array has more than 1 element then convert into a hash
          # check whether each array element contains a key/value pair
          # then create a hash with the arrays contents
          if new_data.length > 1
              if new_data[0].to_s.includes? ":"
                  new_data.each do |data| 
                      data.to_s = data.split(":")
                  end
                  new_data.flatten!
              end
              new_data.slice(2) do |first, second|
                  new_hash[first] = second
              end

          # if array has only one element then check whether it is a
          # hash list. If so, assign the hash to the new_data variable
          elsif new_data[0].is_a? Hash
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
     return "http://" + @address[:ip].to_s + ":" + @address[:port].to_s 
  end

  def restful_request
   return_string = @method_type.upcase + " " + @resources + " " + @format + "\r\n\r\n"
   return_string
  end

  def full_request
   return_string = self.full_address + " " +  @method_type.upcase + " " + 
                   @resources + " " + @format + "\r\n\r\n"
  end


end
