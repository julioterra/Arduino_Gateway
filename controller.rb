require 'socket'
require 'open-uri'
require 'json'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './controller.rb'

module ArduinoGateway

  class ArduinoController
    
      def initialize(public_server)
          @public_server = public_server
          @public_server.register_controller(self)
          @addresses = []
          error_msgs_init

          @debug_code = true

          # @resource_device_list = []    # holds hash with address/id, name and status for each device
          # @resource_service_list = []   # holds hash with id, and name for each service
          # @relationships = []           # holds hash with device id, service id, status, type, and range
      
          # create a thread to listen to keyboard commands
          @key_listener = Thread.new do
          		puts "[ArduinoController:initializer] starting key listener thread"
            	while(@public_server.server_running)
              		input = gets.chomp
              		puts "[ArduinoController:@key_listener] processing your input [#{input}]"
              		if input.include?("X") then
                			puts "[ArduinoController:@key_listener] closing port #{@public_server.public_port_number} and exiting app."
                			@public_server.stop
                			exit
              		end
            	end
          end
          
          # register arduinos specified in the arduino_addrs.json file
          File.open "arduino_addrs.json" do |json_file|
              JSON.parse(json_file.read).each do |cur_set|
                  cur_set = {ip: cur_set["ip"], port: cur_set["port"]}
                  register_arduino(cur_set)
              end
          end
      end


      # REGISTER_ARDUINO
      # register new arduino addresses; accepts hash keys with key/value pairs for ip and port
      def register_arduino(address)
          return unless address_valid?(address)
          @addresses << address
          puts "[ArduinoController:register_arduino] registered new arduino #{address}"
      end


      # SEND_ARDUINO_REQUEST
      # request data from one of the registered arduinos; accepts a request obj
      def send_arduino_request(request)          
          return @address_error unless address_valid?(request.address)
       		ArduinoClient.request(request)
          rescue Exception => e; "#{@timeout_error}, error message #{e}"
      end
    
    
      # REGISTER_PUBLIC_REQUEST
      # receives request from the public server for processing; accepts request (string) and id (int)
      def register_public_request(new_request, request_id)      
          if @debug_code ;	puts "[ArduinoController:register_public_request] request registered" ; end

          # get request data from regex match on request
        	# but first set the regex syntax for matching GET requests 
        	get_request_syntax = /(GET) (\/.*?) (\S*)/	
        	client_get_request_match = get_request_syntax.match(new_request)
        	response = nil

        	# if regex match was found then process the message
        	if (client_get_request_match)
              request = RestfulRequest.new(request_id, $1, $2, $3, @addresses[0])
              response = self.send_arduino_request(request)            
        	end
  
          @public_server.respond(response, request.id)
      end


    private

      # ADDRESS_VALID?
      # checks address validity by confirming data type, and presence of ip and port key
      def address_valid?(address)
          address.is_a?(Hash) && address.include?(:ip) || address.include?(:port)
      end
      
      def error_msgs_init
          @address_error = "<p>Sorry the connection was unsuccessful. There was an issue with the arduino address."
          @timeout_error = "<p>Sorry the connection timed out. We are having some server issues. " +
                     "Be back up soon. Thanks for visiting</p> <p>It's #{Time.now}.</p>"
      end
    
  end
end
