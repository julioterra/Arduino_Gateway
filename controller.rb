require 'socket'
require 'open-uri'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './controller.rb'

class ArduinoController
    
    def initialize(public_server)
  		puts "[ArduinoController:initializer] initializing the Arduino controller"
      @public_server = public_server
      @public_server.register_controller(self)

      # the port number in the address hash is set based on:
      #      (1) greater than 0: these port numbers refer to actual addresses 
      #          and so if the port number is greater than 0 than address can 
      #          considered to be SET
      #      (2) -1: port address has not been set yet
      #      (3) -11: request should be ignored without raising exceptions or redirecting
      #      (3) -12: request return an exception in the form of a missing resource page
      @addresses = {"wait" => {:ip => "0.0.0.0", :port => -1},
                    "ignore" => {:ip => "0.0.0.0", :port => -11},
                    "error" => {:ip => "0.0.0.0", :port => -12}}
      @route
      
      # create a thread to listen to keyboard commands
      @key_listener = Thread.new do
    		puts "[ArduinoController:initializer:key_listener] starting key listener thread"
      	while(@public_server.server_running)
      		input = gets.chomp
      		puts ": processing your input [#{input}]"
      		if input.include?("X") then
      			puts "[ArduinoController:initializer:key_listener] closing port #{@public_port_number} and exiting app..."
      			@public_server.stop
      		end
      	end
      end
    end

    # register new arduino addresses (id, ip and port)
    # saves new address in the @addresses array. Input should 
    # be a hash key with two value:
    #     :name - holds the name of the arduino
    #     :content - holds a hash key with :ip and :port key/value pairs
    def register_arduino(address)
      unless address.empty? || !address.is_a?(Hash)
          begin
              @addresses.merge!({address[:name] => address[:content]}) 
              puts "[ArduinoController:register_arduino] finished registering new arduino #{p @addresses}"
          rescue => e
              puts "[ArduinoController:register_arduino] ERROR: unable to register new arduino: #{e.message}"
          end
      end
    end

    # request data from one of the registered arduino
     def request(request)

       if request.address.equal?(@addresses["ignore"])
           puts "[ArduinoController:request] -#{request.id.to_i}- ignored address: #{request.full_request.chomp}"           
           response = ""
       else
            begin
                puts "[ArduinoController:request] -#{request.id.to_i}- valid address: \n#{request.full_request.chomp}"
         		    response = ArduinoClient.request(request)
     		     rescue Exception => e
                puts "[ArduinoController:request] -#{request.id.to_i}- ERROR: #{e.message}"
                response = "<p>Sorry the connection timed out. We are having some server issues. " +
                                         "Be back up soon. Thanks for visiting</p>" +
                                         "<p>It's #{Time.now}.</p>"
   		     end
       end
	     response
    end
    
    
    def register_request(new_request, request_id)
      debug_code = true
      
      if debug_code ;	puts "[ArduinoController:register_request] got here" ; end
      # get request data from regex match on request
    	# but first set the regex syntax for matching GET requests 
    	get_request_syntax = /(GET) (\/.*?) (\S*)/	
    	client_get_request_match = get_request_syntax.match(new_request)
    	response = -1

    	# if regex match was found then process the message
    	if (client_get_request_match)
          request = RestfulRequest.new(request_id, $1, $2, $3)

          if debug_code 
          		puts "[ArduinoController:register_request] -#{request.id.to_i}- matches syntax: "
  		    end

      		# check for resources that should be ignored
      		if (request.resources =~ /\/favicon.ico/) 
              request.address = @addresses["ignore"]

          # process resources that should be routed
          else
              request.address = @addresses["worktable"]
      		end
      		
          # routed_request = self.route(request)
          response = self.request(request)
    	end
      if debug_code ;	puts "[ArduinoController:register_request] -#{request.id.to_i}- calling @public_server.respond method" ; end

      @public_server.respond(response, request.id)
    end
    
    def route(request)
        
        request
    end
    
end
