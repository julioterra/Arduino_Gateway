require 'socket'
require 'open-uri'
require 'json'
require './helpers.rb'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './model.rb'
require './model_base.rb'
require './controller_helpers.rb'

module ArduinoGateway
  module Control

    class Controller
        include ::ArduinoGateway::Helpers
        include ::ArduinoGateway::Control::ControlHelpers

        def initialize(public_server)
          @public_server = public_server
          @public_server.register_controller(self)
          @addresses = []
          @debug_code = true

          # create a thread to listen to keyboard commands
          @key_listener = Thread.new do
        		puts "[Controller:initializer] starting key listener thread"
          	while(@public_server.server_running)
          		input = gets.chomp
          		puts "[Controller:@key_listener] processing your input [#{input}]"
          		if input.include?("X") then
          			puts "[Controller:@key_listener] closing port #{@public_server.public_port_number} and exiting app."
          			@public_server.stop
          			exit
          		end
          	end
          end
        
          # register arduinos specified in the arduino_addrs.json file
          File.open "arduino_addrs.json" do |json_file|
            JSON.parse(json_file.read).each do |cur_arduino|
              new_arduino = {name: cur_arduino["name"], 
                             ip: cur_arduino["ip"], 
                             port: cur_arduino["port"]}
              register_arduino(new_arduino)
            end
          end
        end

        # REGISTER_ARDUINO
        # register new arduino addresses; accepts hash keys with key/value pairs for ip and port
        def register_arduino(address)
          return false unless address_valid?(address)
          @addresses << address
          device = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceDevice.new address
          puts "[Controller:register_arduino] registered new arduino #{address}, now making info request"

          arduino_services = make_request RestfulRequest.new(-1, "GET /resource_info", address)
          register_services arduino_services, device.id
          true
        end
      
        def register_services(arduino_services, device_id)
          # arduino_services.match /^(?:HTTP.*\n[A-Za-z].*\n.*\n){1}((?:.*\n*)*)\n/
          arduino_services.match /^(?:[A-Za-z].*\n)*([\[|\{](?:.*\n*)*)\n/
          return unless services_json = $1

          JSON.parse(services_json).each do |services|
            services["resource_name"].match /(^\D*)(?:_\d)*$/
            return unless service_type_name = $1
            
            # CHANGE - check if this is a new service type 
            service_id = get_service_id(service_type_name)
            new_instance = {name: services["resource_name"], 
                           post_enabled: services["post_enabled"],
                           range_min: services["range"]["min"],
                           range_max: services["range"]["max"],
                           device_id: device_id, service_type_id: service_id}
            new_service_record = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceInstance.new new_instance

            
          end
        end
              
        # SEND_ARDUINO_REQUEST
        # request data from one of the registered arduinos; accepts a request obj
        def make_request(new_request)          
            puts "[Controller:make_request] request '#{new_request.id}' will be submitted to arduino"
            return error_msg(:arduino_address) unless address_valid?(new_request.address)
         		return Interface::ArduinoClient.register_request(new_request)
            rescue Exception => error; return error_msg(:timeout, error)
        end

        # SUBMIT_PUBLIC_REQUEST
        # receives request from the public server for processing; accepts request (string) and id (int)
        def register_request(request_string, request_id)      
          # puts "[Controller:register_request] request string: #{request_string}"
          if request_string.match /(GET|POST)/
            process_request request_string, request_id
          else
            @public_server.respond error_msg(:request_not_supported), request_id
          end
        end

        # PROCESS_REQUEST - WIP, WIP, WIP, WIP
        # 1. read public request and determine which arduino requests need to be made
        # 2. initialize timer to ensure that response to request does not take too long
        # 3. create an array with the appropriate requests
        # 4. iterate through the array and make the appropriate requests
        # 5. add responses to a response array
        # 6. call process_response method and pass it the response array along with the request_id
        def process_request(request_string, request_id)      
          new_request = RestfulRequest.new(request_id, request_string, @addresses[0])
          response = make_request new_request  
          # puts "[Controller:process_request] response received from request id '#{request_id}'"
          # puts "[Controller:process_request] processing request: #{new_request.full_request}"
          process_response(response, new_request)
        end


        # PROCESS_RESPONSE - WIP, WIP, WIP, WIP
        # 1. iterate through array in order to create a single response string
        # 2. respond to public request by calling the 
        def process_response(responses, request)      
          @public_server.respond responses, request.id.to_i
        end

    end # Controller class

  end # Control module
end # ArduinoGateway module
