class PublicServer 
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

     def request_from_arduino (request, private_server_msg, arduino_host_ip, arduino_port_number)
         begin
             
             puts "[read_data] requesting data from arduino ****"
             response = ArduinoClient.request(request)
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
                    request = RestfulRequest.new($1, $2, $3)
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
                      request.address = {ip_host: @arduino_host_ip, port: @arduino_port_number}
              		    response = request_from_arduino(request, "GET / HTTP/1.0\r\n\r\n", @arduino_host_ip, @arduino_port_number)
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