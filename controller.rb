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
        attr_accessor :timer

        def initialize(public_server)
          @public_server = public_server
          @public_server.register_controller(self)
          Interface::ArduinoClient.register_controller(self)
          @arduinos = {}
          @debug_code = true
          @timer = Timer.new

          # not yet implemented
          @active_requests = {}
          # not yet implemented
          
          # create a thread to listen to keyboard commands
          @key_listener = Thread.new do
            begin
          		puts "[Controller:initializer] starting key listener thread"
              while(true)       
            		input = STDIN.gets.chomp
            		puts "[Controller:@key_listener] processing your input [#{input}]"
            		if input.include?("X") then
            			puts "[Controller:@key_listener] closing port #{@public_server.public_port_number} and exiting app."
            			@public_server.stop
            			exit
            		end
            	end
          	rescue => e
          	  puts "[Controller:@key_listener] thread stopped #{e.backtrace}"
          	end
          end
        
          # register arduinos specified in the arduino_addrs.json file
          File.open "arduino_addrs.json" do |json_file|
            JSON.parse(json_file.read).each do |cur_arduino|
              @arduinos[cur_arduino["name"].to_sym] = {name: cur_arduino["name"],
                                                       ip: cur_arduino["ip"], 
                                                       port: cur_arduino["port"],
                                                       registered: false}
              register_arduino(cur_arduino["name"].to_sym)
            end
          end
        end # initialize method

        ######################################
        # REGISTER_ARDUINO
        # register new arduino addresses; accepts hash keys with key/value pairs for ip and port
        def register_arduino(name)
          return false unless name.is_a? Symbol and address_valid?(@arduinos[name])
          device = ::ArduinoGateway::Model::ModelTemplates::ResourceDevice.new @arduinos[name]
          @arduinos[name][:device_id] = device.id        
          make_request RestfulRequest.new(-1, "GET /resource_info", @arduinos[name])
        end # register_arduino method
        
      
        ######################################
        # REGISTER_SERVICES
        # Method called to parse info_requests made to each device when registered      
        def register_services(arduino_services, device_id)
          # arduino_services.match /^(?:HTTP.*\n[A-Za-z].*\n.*\n){1}((?:.*\n*)*)\n/
          arduino_services.match /^(?:[A-Za-z].*\n)*([\[|\{](?:.*\n*)*)\n/
          return unless services_json = $1

          JSON.parse(services_json).each do |services|
            services["resource_name"].match /(^\D*)(?:_\d)*$/
            return unless service_type_name = $1
            # puts "[Controller:register_services] current resource name matched '#{$1}'"
            
            # get service id by finding existing service id, or adding a new service if needed 
            service_id = get_service_id(service_type_name)
            new_instance = {name: services["resource_name"], 
                           post_enabled: services["post_enabled"],
                           range_min: services["range"]["min"],
                           range_max: services["range"]["max"],
                           device_id: device_id, service_type_id: service_id}
            new_service_record = ::ArduinoGateway::Model::ModelTemplates::ResourceInstance.new new_instance            
          end
        end # register_services method
              

        ######################################              
        # REGISTER_REQUEST // CALLBACK API METHOD
        # Method called by public server to register new request
        # Accepts: request_string (string), request_id (int)
        def register_request(request_string, request_id)      

          puts "[Controller:register_request] request string: #{request_string}"
          if request_string.match /(GET|POST)/
            @active_requests[request_id] = {public_request: request_string, 
                                            received_on: Time.now.to_i,
                                            arduino_requests: [],
                                            arduino_responses: [],
                                            public_response: ""}
            puts "[Controller:register_request] new request, id: #{request_id}, content: #{@active_requests}"
            process_request request_string, request_id

            @timer.new_timer(1) do
              unless @active_requests[request_id].nil?
                process_response @active_requests[request_id][:arduino_responses], request_id 
              end
            end

          else
            @public_server.respond error_msg(:request_not_supported), request_id
          end
        end # register_request method
        

        ######################################
        # PROCESS_REQUEST 
        # 1. read public request and determine which arduino requests need to be made
        # 2. create an array with the appropriate requests
        # 3. pass the array to the make_request method
        def process_request(request_string, request_id)      

          new_requests = []
          
          # parse the URL into verb, resources, options, and body
          request_string.match /(GET|POST) \/(\S*)(.*)^(.*)\Z/m
          request_verb, request_resources, request_options, request_body = $1, $2, $3, $4
          device_info, device_resources = {}, ["json"]

          # handle generic requests (for all devices and services)
          if request_resources.empty?
            @arduinos.each do | key, address |
              new_request_string = "#{request_verb} /#{device_resources.join("/")}#{request_options}#{request_body}"
              new_requests << RestfulRequest.new(request_id, new_request_string, address)              
            end

          # handle requests for specific devices and services
          else
            parsed_request = request_resources.split("/")
            parsed_request.shift if parsed_request[0].eql? "json"
            device_match = ::ArduinoGateway::Model::ModelTemplates::ResourceDevice.find_by_name(parsed_request[0])
            puts "[Controller:process_request] checking if request starts with device name: #{parsed_request[0]}"

            # handle requests for services from specific device
            if !device_match.empty?
              # puts "[Controller:process_request] device specific request confirmed: #{device_match}"
              parsed_request.shift 
              device_info = {id: device_match[0].id, ip: device_match[0].ip, port: device_match[0].port}

              # handle service instance requests
              service_instance_match = ::ArduinoGateway::Model::ModelTemplates::ResourceInstance.find_by_device_id(device_info[:id])              
              if !service_instance_match.empty?
                # puts "[Controller:process_request] services found: #{service_instance_match}"
                parsed_request.each do | service_name |
                  service_instance_match.each do | service_instance |
                    # puts "[Controller:process_request] mached service: #{service_instance.name} : #{service_name}"
                    device_resources << service_name if service_instance.name.to_s.eql? service_name
                  end
                end
              end

              # handle generic service requests
              parsed_request.each do | service_name |
                generic_service_match = ::ArduinoGateway::Model::ModelTemplates::ResourceService.find_by_name(service_name)              
                if !generic_service_match.empty?
                  puts "[Controller:process_request] generic services found: #{generic_service_match}"
                  service_id = generic_service_match[0].id.to_i
                  service_instance_match.each do | service_instance |
                    puts "[Controller:process_request] mached service: #{service_instance.service_type_id} : #{service_id}"
                    device_resources << service_instance.name if service_instance.service_type_id == service_id
                  end
                end
              end

              puts "[Controller:process_request] services requested: #{device_resources}"              
              new_request_string = "#{request_verb} /#{device_resources.join("/")}#{request_options}#{request_body}"
              new_requests << RestfulRequest.new(request_id, new_request_string, device_info)              
              
            # handle requests for services across devices
            else 
              services_by_device = {}
              
              # loop through parsed public request to identify services being requested
              parsed_request.each do | service_name |

                # look for specific service requests using service name
                service_instance_match = ::ArduinoGateway::Model::ModelTemplates::ResourceInstance.find_by_name(service_name)              
                service_instance_match.each do | service_instance |
                  puts "[Controller:process_request] matched service: #{service_instance.name} on #{service_instance.device_id}"
                  if services_by_device[service_instance.device_id.to_i] 
                    services_by_device[service_instance.device_id.to_i] << service_instance.name.to_s
                  else 
                    services_by_device[service_instance.device_id.to_i] = [service_instance.name.to_s]
                  end
                end # service_instance_match.each iterator

                # look for general service requests
                generic_service_match = ::ArduinoGateway::Model::ModelTemplates::ResourceService.find_by_name(service_name)              
                unless generic_service_match.empty?
                  puts "[Controller:process_request] generic service found: #{generic_service_match}"
                  service_id = generic_service_match[0].id.to_i
                  # find the individual service instances using service_id
                  service_instance_match = ::ArduinoGateway::Model::ModelTemplates::ResourceInstance.find_by_service_type_id(service_id)              
                  service_instance_match.each do | service_instance |
                    puts "[Controller:process_request] matched service: #{service_instance.name} on #{service_instance.device_id}"
                    if services_by_device[service_instance.device_id.to_i] 
                      services_by_device[service_instance.device_id.to_i] << service_instance.name.to_s
                    else 
                      services_by_device[service_instance.device_id.to_i] = [service_instance.name.to_s]
                    end
                  end # service_instance_match.each iterator
                end # unless generic_service_match.empty?
              end # parsed_request.each iterator

              # loop services by device to create private requests 
              services_by_device.each do | device , services |
                services.each { | service | device_resources << service }
                device_resources.uniq!
                puts "[Controller:process_request] services: #{device_resources} on #{device}"
                device_match = ::ArduinoGateway::Model::ModelTemplates::ResourceDevice.find_by_id(device.to_i)
                unless device_match.empty?
                  device_info = {id: device_match[0].id, ip: device_match[0].ip, port: device_match[0].port}
                  puts "[Controller:process_request] services requested from device /#{device_resources.join("/")}: #{device_resources}"              
                  new_request_string = "#{request_verb} /#{device_resources.join("/")}#{request_options}#{request_body}"
                  new_requests << RestfulRequest.new(request_id, new_request_string, device_info)       
                end # unless device_match.empty?  
              end # services_by_device.each

            end # parsed_request.each
          end # else related to requests for specific devices and services

          @active_requests[request_id][:arduino_requests] = new_requests.map  { | request | make_request request }             
        end # process_request



        ######################################
        # MAKE_REQUEST
        # method that sends individual requests to specific devices
        def make_request(new_request)          
            puts "[Controller:make_request] request '#{new_request.id}' will be submitted to arduino"
            return error_msg(:arduino_address) unless address_valid?(new_request.address)
         		return Interface::ArduinoClient.register_request(new_request)
            rescue Exception => error; return error_msg(:timeout, error)
        end

        ######################################
        # REGISTER_RESPONSE // CALLBACK API METHOD
        # Method called by the ArduinoClient class to register responses to request
        def register_response(response, request)

          # if reponse is to an info_request then register services
          if request.id == -1 
            register_services response, request.address[:device_id]          

          # else handle response like a normal resource request
          else 
            @active_requests[request.id][:arduino_responses] << response                       
            requests = @active_requests[request.id][:arduino_requests].length
            responses = @active_requests[request.id][:arduino_responses].length
            if responses >= requests
              process_response(@active_requests[request.id][:arduino_responses], request.id) 
              @active_requests.delete(request.id)              
            end
          end
        end # register_response method


        ######################################
        # PROCESS_RESPONSE 
        # Method called when all responses have been received or when request times out
        # 1. iterate through response in order to create a single response string
        # 2. respond to public request by calling the 
        def process_response(responses, request_id)      
          unless @active_requests[request_id][:arduino_responses].empty?
            @public_server.respond @active_requests[request_id][:arduino_responses][0], request_id
          else

            ######################################
            # need to send an error message as public response if no arduino responses were registered
            @public_server.respond "", request_id
            ######################################

          end
        end # process_response method

    end # Controller class

  end # Control module
end # ArduinoGateway module
