require 'socket'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

class TimeoutException < Exception 
end

class ArduinoServer 
    attr_accessor :arduino_list, :error

    def initialize (public_port, arduino_port)
        # ip address and host numbers
        @public_port_number = public_port.to_i
        @arduino_port_number = arduino_port.to_i
        @arduino_host_ip = ""
        @arduino_list = []
              
        @server = TCPServer.new(@public_port_number)  
        @server_running = true
        @client_count = 0 
        @thread_count = 0
                      
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
    end

    # for setting the arduino host ip
    def register_arduino (arduino_host_ip)
      arduino_list << arduino_host_ip
      @arduino_host_ip = arduino_host_ip
    end


    def connect_to_arduino(client, timeout=2)
        addr = Socket.getaddrinfo(@arduino_host_ip, nil)  
        @socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

        timer = Thread.new(@socket, client) do |socket_connection, client_connection|
            start_time = Time.now.sec
            end_time = start_time + 2
            puts "before loop #{start_time}, #{end_time}"
            begin
                loop do
                    current_time = Time.now.sec
                    if current_time < start_time then current_time += 60 end
                    if current_time > end_time 
                      raise TimeoutException, "Taking too long." 
                      # client_connection.puts results
                      # socket_connection.close
                      # client_connection.close
                      # destroy
                    end
                end
             rescue TimeoutException => e
                error = "<p>We are having some server issues. Be back up soon. Thanks for visiting<br/>#{Time.now}/</p>"
                puts error
                # client_connection.puts error
                @socket.close
                # client_connection.close
                puts "Error Rescue: ports closed and exceptions results sent.\n"
                puts "Error Message: #{e.message},", e.backtrace
                destroy
            end
            puts "after loop #{start_time}, #{end_time}"
         end

        connection_status = @socket.connect(Socket.pack_sockaddr_in(@arduino_port_number, addr[0][3]))
        if (connection_status == 0)
          timer.kill
          true
        else
          false
        end
    end

    def stop
      @server_running = false
			@server.close 
			exit
    end

    def run
        # while the server is accepting clients 
        while (@server_running && client = @server.accept) 
          	@client_count += 1

      	    Thread.new client do |client_connection|
                results = "<p>It's #{Time.now} and we are having some server issues. Be back up soon. Thanks for visiting</p>"

                # read request from client and print request length
              	client_data = client.recvfrom(1500)[0].chomp.to_s
              	puts "\nrequest length: #{client_data.length}"
                # puts "#{client_data}"

              	# get request data from regex match on client_data
              	# but first set the regex syntax for matching GET requests 
              	get_request_syntax = /(GET) (\/.*?) (\S*)/	
              	client_get_request_match = get_request_syntax.match(client_data)

              	# if regex match was found then process the message
              	if (client_get_request_match)
                		puts "request message: #{client_get_request_match[0]}"
                		puts "request type: #{client_get_request_match[1]}"
                		puts "request resource: #{client_get_request_match[2]}"
                		puts "request format: #{client_get_request_match[3]}"

                		# make sure that resource being requested was not /favicon.ico
                		if !(client_get_request_match[2] =~ /\/favicon.ico/) 
                        puts "match found #{(client_get_request_match[2] =~ /\/favicon.ico/)}"

                      # Thread.new client do |client_connection|
                				@thread_count += 1	

                        # connect to arduino, and read data from the @socket if connection was successful
                        if (connect_to_arduino(client_connection))
                          	@socket.write( "GET / HTTP/1.0\r\n\r\n" )
                          	results = @socket.read
                            @socket.close
                        end			  

                				results += "client_count: #{@client_count.to_s} thread_count: #{@thread_count.to_s}<br />\n" +
                						       "requested resource: #{client_get_request_match[2]}"      

                    		# send the results back to the client on port 7999
                				client_connection.puts results  # Send the time to the client
                        client_connection.close

                				# display the results on the terminal
                				puts "server response to client: \n#{results}"
                      # end
                    else
              				  client_connection.puts error  # Send the time to the client
                        client.close
                		end
              	end
            end
        end
    end
end

arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
public_port_number = 7996

arduino_server = ArduinoServer.new(public_port_number, arduino_port_number)
arduino_server.register_arduino(arduino_host_ip)
arduino_server.run

