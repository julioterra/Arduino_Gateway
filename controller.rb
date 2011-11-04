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
      @arduino_clients = {} # {"basic_sensors" => {host_ip: "0.0.0.0", port: -1}}

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

    # for setting the arduino host ip
    def register_arduino(arduino_host_ip)
      @arduino_clients.merge!(arduino_host_ip)
      @arduino_host_ip = arduino_host_ip
      puts "[ArduinoController:register_arduino] finished registering arduinos #{p @arduino_clients}"
    end

     def request(request)
         begin
             response = ArduinoClient.request(request)
             puts "[ArduinoController/request] returning data read from arduino read method"
             response
         rescue Exception => e
             puts "ERROR [ArduinoController/request]  #{e.message}"
             response = "<p>It's #{Time.now} and we are having some application issues. " + 
                      "Be back up soon. Thanks for visiting</p>"
             response
         end
    end
    
    
    def register_request(new_request, request_id)
      debug_code = true
      
      if debug_code ;	puts "[ArduinoController:handle_request] got here" ; end
      # get request data from regex match on request
    	# but first set the regex syntax for matching GET requests 
    	get_request_syntax = /(GET) (\/.*?) (\S*)/	
    	client_get_request_match = get_request_syntax.match(new_request)
    	response = -1

    	# if regex match was found then process the message
    	if (client_get_request_match)
          request = RestfulRequest.new(request_id, $1, $2, $3)
          if debug_code 
          		puts "[ArduinoController:handle_request] request FULL message: #{p request}"
  		     end

      		# make sure that resource being requested was not /favicon.ico
      		if (client_get_request_match[2] =~ /\/favicon.ico/) 
            print_string = "[ArduinoController:handle_request] response CONFIRMATION - Message NOT Sent \n" +
                           # "[ArduinoController:handle_request] response Client Number: #{current_client}\n" +
                           "[ArduinoController:handle_request] response No Appropriate Response"
          else
            request.address = {ip_host: '192.168.2.200', port: 7999}
    		    response = self.request(request)
            print_string = "[ArduinoController:handle_request] response CONFIRMATION - Message Sent \n" +
                           "[ArduinoController:handle_request] response Response Data: \n#{response}"
      		end
          if debug_code ; puts print_string ; end
    	end
      if debug_code ;	puts "[ArduinoController:handle_request] calling @public_server.respond method" ; end

      @public_server.respond(response, request.id)
    end
end
