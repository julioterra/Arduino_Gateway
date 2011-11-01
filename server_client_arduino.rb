require 'socket'
require 'open-uri'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

class TimeoutException < Exception 
end



class RestfulRequests
   attr_accessor :method_type, :format, :options
   attr_reader :resources_list, :resources, :address
   
   def initialize(method, resources, format)
      puts "[RestfulRequests:initialize] initializing server request object"
        @method_type = method
        @format = format
        @resources = resources
        @address = {:ip_host => "0.0.0.0", :channel => -1}
        @options = {}
        self.resources_list = @resources
        puts "[RestfulRequests:initialize] finished initializing, - num of resource: #{@resource_list.length}"
        puts "[RestfulRequests:initialize] finished initializing, - num of resource: #{@address}"
        self.print
   end
   
   def resources=(resources_in)
     @resources = resources_in
     self.resource_list = @resources
   end

   def address=(ip_host, channel)
     @address[:ip_host] = ip_host.to_s
     @address[:channel] = channel.to_i
   end

   def address
      return "http://" + @address[:ip_host].to_s + ":" + @address[:channel].to_s 
   end

   def options=(*option_in)
       if (option_in.kind_of? String)
         @option = option_in
         elsif ((option_in.kind_of? Array) || (option_in.kind_of? Hash))
         @option = option_in.join " "
       end
   end

   ## FULLY WORKING FUNCTION
   #  
   def resources_list=(resource_in)
     debug_code = false
     if debug_code ; puts "[RestfulRequests:resource_list:0] creating a resource object: #{resource_in}"; end

     #handle string input
     if (resource_in.kind_of? String)
         # create a list of resources (disregard first position, which is blank) 
         # then reformat each entry to include a starting forward slash
         # lastly, add an ending forward slash, if appropriate
         if debug_code ; puts "[RestfulRequests:resource_list:1] string input" ; end
         @resource_list = resource_in[1..-1].split('/')   
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
  
    def resource_list_update_with_array=(resource_in)
        if (resource_in.kind_of? Array)
            @resource_list = resource_in.map { |resource| 
              if !resource.chomp.start_with?('/') ; resource = '/' + resource ; end
            } 
            @resources = @resource_list.join
        end
    end
    
   def print
     puts "[RestfulRequests:print] resftul request: #{self.get_restful_request}"
     puts "[RestfulRequests:print] full request: #{self.get_full_request}"
     puts "[RestfulRequests:print] address: #{self.address}"
     
     recompiled_resource = @method_type.upcase + " " + @resource_list.join + " " + @format
     puts "[RestfulRequests:print] request recompiled: #{recompiled_resource}"
   end

   def get_restful_request
     return_string = @method_type.upcase + " " + @resources + "\r\n\r\n"
     # puts "[RestfulRequests:get_request] RESTful request: #{return_string}"
     return_string
   end

   def get_full_request
     return_string = @address[:ip_host].to_s + " " + @address[:channel].to_s + " " + 
                     @method_type.upcase + " " + @resources + " " + @format + "\r\n\r\n"
     # puts "[RestfulRequests:get_full_request] FULL request: #{return_string}"
   end


end




class ArduinoServer 
    attr_accessor :arduino_list, :debug_code, :server

    def initialize (public_port, arduino_port)
        puts "[ArduinoServer:new] ******************************"
        puts "[ArduinoServer:new] starting up the ArduinoServer"
        # puts "[ArduinoServer:new] files in data directory: #{`ls ./data/`}"
        puts "[ArduinoServer:new] ******************************"
        # ip address and host numbers
        @public_port_number = public_port.to_i
        @arduino_port_number = arduino_port.to_i
        @arduino_host_ip = ""
        @arduino_list = []
        @debug_code = true      
        begin        
            @server = TCPServer.new(@public_port_number)  
            @server_running = true
            @client_count = 0 
            @thread_count = 0
          rescue => e
            puts "[ArduinoServer:new] RESCUE: error with server #{e.message}"
        end
                      
        # create a thread to listen to keyboard commands
        @key_listener = Thread.new do
        	while(@server_running)
        		input = gets.chomp
        		puts "processing your input [#{input}]"
        		if input.include?("X") then
        			puts "closing port #{@public_port_number} and exiting app..."
        			stop
        		end
        	end
        end
        puts "[ArduinoServer:new] finished start-up"
    end
    

    # for setting the arduino host ip
    def register_arduino (arduino_host_ip)
      @arduino_list << arduino_host_ip
      @arduino_host_ip = arduino_host_ip
      puts "[ArduinoServer:new] finished registering arduinos"
    end
    

    def connect_to_arduino(arduino_host_ip, request_message, timeout=2)
        # holds current connection status with an Arduino
        #  -1 = connection unavailable
        #   0 = establishing connection
        #   1 = connection established
        #   2 = connection completed
        connection_status = 0
        response = -1
        
        # ARDUINO_CONNECTION thread
        # thread responsible for connecting to and captuing response from the arduino
        arduino_connection = Thread.new (arduino_host_ip) do |host_ip| 
            # use the thread keys to store information about the connection status and the server's response
            Thread.current[:status] = 0
            Thread.current[:response] = 0

            addr = Socket.getaddrinfo(host_ip, nil)  
            socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

            if @debug_code then puts "[register_arduino/arduino_connection] - trying to connect\n" end

            begin
                connection_status = socket.connect(Socket.pack_sockaddr_in(@arduino_port_number, addr[0][3]))
                if Thread.current[:status].to_i == 0
                    Thread.current[:status] = 1
                   	socket.write( request_message )
                   	Thread.current[:response] = socket.read
                    socket.close
                    Thread.current[:status] = 2
                end
              rescue => e
                  puts "[connect_to_arduino/arduino_connection] ERROR: \n #{e.message} \n#{e.backtrace}"
            end
        end

        # TIMER thread
        # thread responsible ending the connection attempt after a pre-specified timeout
        timer = Thread.new(arduino_connection, timeout) do |con_thread, timeout_time|
            start_time = Time.now.sec
            end_time = start_time + timeout_time
            begin
                loop do
                    if !(con_thread[:status] == 1 || con_thread[:status] == 2) 
                      current_time = Time.now.sec
                      if current_time < start_time then current_time += 60 end
                      if (current_time > end_time) then raise TimeoutException, "Taking too long." end
                    else
                      if @debug_code then puts "[connect_to_arduino/timer] Timer: stopping thread loop : status #{con_thread[:status]}" end
                      break
                    end
                end
             rescue TimeoutException, Exception => e
                con_thread[:status] = -1
                con_thread[:response] = "<p>It's #{Time.now} and we are having some server issues. " +
                                        "Be back up soon. Thanks for visiting</p>"
                puts "[connect_to_arduino/timer] ERROR: connection timed out - #{e.message}\n"
            end
         end
                
        while(arduino_connection[:status].to_i == 0 || arduino_connection[:status].to_i == 1)
        end
          
        # puts "set response with arduino_connection #{arduino_connection[:response]}"
        response = arduino_connection[:response]
        # puts "response set with arduino_connection #{response}"
          
        if !timer.stop? then timer.stop end
        if !arduino_connection.stop? then arduino_connection.stop end

        if @debug_code 
          puts "[connect_to_arduino]: returning data from arduino socket" 
        end
        response

    end

     def request_from_arduino (private_server_msg)
         begin
             response = connect_to_arduino(@arduino_host_ip, private_server_msg)
             puts "[read_data] returning data read from arduino read method"
             response
         rescue Exception => e
             puts "ERROR [read_data]  #{e.message}"
             response = "<p>It's #{Time.now} and we are having some application issues. " + 
                      "Be back up soon. Thanks for visiting</p>"
             response
         end
    end

    def run
        debug_code = false
        if debug_code ; puts "RUN: starting to run - server status: #{@server_running}" ; end
        # while the server is accepting clients 
        while (@server_running && client = @server.accept) 
          if debug_code ; puts "RUN: at top of while loop" ; end

          	@client_count += 1
      	    Thread.new client do |client_connection|
              	current_client = @client_count
                if debug_code
                  puts "RUN:acccepting client ID: #{@current_client}"
                end
                
                # read request from client and print request length
              	client_data = client_connection.recvfrom(1500)[0].chomp.to_s
                if debug_code 
                    puts "\nRUN:client ID: #{current_client}", 
                   "RUN:request length: #{client_data.length}"
                   # "#{client_data}"
                end

              	# get request data from regex match on client_data
              	# but first set the regex syntax for matching GET requests 
              	get_request_syntax = /(GET) (\/.*?) (\S*)/	
              	client_get_request_match = get_request_syntax.match(client_data)

              	# if regex match was found then process the message
              	if (client_get_request_match)
                    resource_request = RestfulRequests.new($1, $2, $3)
                    if debug_code 
                    		puts "RUN:request FULL message: #{client_get_request_match[0]}",
                    		     "RUN:request type: #{client_get_request_match[1]}",
                    		     "RUN:request resource: #{client_get_request_match[2]}",
                    		     "RUN:request format: #{client_get_request_match[3]}"
            		     end

                		# make sure that resource being requested was not /favicon.ico
                		if (client_get_request_match[2] =~ /\/favicon.ico/) 
                      client_connection.close
                      print_string = "RUN:response CONFIRMATION - Message NOT Sent \n" +
                                     "RUN:response Client Number: #{current_client}\n" +
                                     "RUN:response No Appropriate Response"
                    else
              		    response = request_from_arduino("GET / HTTP/1.0\r\n\r\n")
                      client_connection.puts response
                      client_connection.close
                      print_string = "RUN:response CONFIRMATION - Message Sent \n" +
                                     "RUN:response Client Number: #{current_client}\n" +
                                     "RUN:response Response Data: \n#{response}"
                		end
                    if debug_code ; puts print_string ; end
              	end
                client_connection.close
            end

        end
    end
   
    def stop
      @server_running = false
			@server.close 
			exit
    end
       
end

arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
public_port_number = 7996

# ALTERNATE WAY TO GET DATA FROM ARDUINO 
# arduino_page = open("http://192.168.2.200:7999/")
# puts "**************************" +
#      "here is the test page content: \n"
# p arduino_page.read  # returns main content 
# p arduino_page.meta  # returns content type

arduino_server = ArduinoServer.new(public_port_number, arduino_port_number)
arduino_server.register_arduino(arduino_host_ip)
arduino_server.run

