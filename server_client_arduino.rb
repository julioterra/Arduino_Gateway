require 'socket'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

class TimeoutException < Exception 
end

class ServerRequests
    
end

class ArduinoServer 
    attr_accessor :arduino_list, :results, :socket

    def initialize (public_port, arduino_port)
        # ip address and host numbers
        @public_port_number = public_port.to_i
        @arduino_port_number = arduino_port.to_i
        @arduino_host_ip = ""
        @arduino_list = []
        @results = ""
              
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


    def connect_to_arduino(client, private_server_msg, timeout=2)

        # holds current connection status with an Arduino
        #   0 = establishing connection
        #   1 = connection established
        #  -1 = connection unavailable
        connection_status = 0
        
        # thread
        connect_thread = Thread.new(client) do |client_connection|
            addr = Socket.getaddrinfo(@arduino_host_ip, nil)  
            socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
            Thread.current[:status] = 0
            puts "connect_thread - trying to connect - #{Thread.current[:status]}\n  "
            begin
                connection_status = socket.connect(Socket.pack_sockaddr_in(@arduino_port_number, addr[0][3]))
                puts "SUCCESS: connection established"
                if Thread.current[:status].to_i == 0
                    puts "SUCCESS: connection established"
                    Thread.current[:status] = 1
                    puts "SUCCESS: write request"
                   	socket.write( private_server_msg )
                   	@results = socket.read
                    puts "SUCCESS: message read #{@results}"
                    socket.close
                    client_connection.puts @results
                    client_connection.close
                    Thread.current[:status] = 2
                end
              rescue => e
                puts "ERROR [connect_to_arduino/connect_thread] \n #{e.message} \n#{e.backtrace}"
            end
        end

        timer = Thread.new(client, connect_thread) do |client_connection, con_thread|
            start_time = Time.now.sec
            end_time = start_time + timeout
            puts "#{start_time} + #{timeout}"
            begin
                loop do
                    current_time = Time.now.sec
                    if current_time < start_time then current_time += 60 end
                    if (current_time > end_time) then raise TimeoutException, "Taking too long." end
                    if con_thread[:status] == 1 || con_thread[:status] == 2 
                      puts "** Timer Stopping at Thread Status #{con_thread[:status]}"
                      Thread.stop 
                    end
                end
             rescue TimeoutException, Exception => e
                if con_thread[:status].to_i == 0
                    @results = "<p>It's #{Time.now} and we are having some server issues. Be back up soon. Thanks for visiting</p>"
                    puts "FAILURE: connection not established - #{e.backtrace}\n"

                    # socket_connection.close
                    client_connection.puts @results
                    client_connection.close
                    con_thread[:status] = -1
                end
            end
         end
                
        while(connect_thread[:status].to_i == 0 || connect_thread[:status].to_i == 1)
        end
          
        if !timer.stop? then timer.stop end
        if connect_thread.stop? then connect_thread.stop end

        if (connect_thread[:status] == 2)
          puts "return true #{@results}"
          # connect_thread.stop
          return 0
        elif if (connect_thread[:status] == -1)
          puts "return false"
          # connect_thread.stop
          return -1
        end
    end

     def read_data (client_connection, private_server_msg)
         begin
             connect_to_arduino(client_connection, private_server_msg)
         rescue Exception => e
             puts "ERROR [read_data]  #{e.message}"
         end
         @results
    end

    def stop
      @server_running = false
			@server.close 
			exit
    end

    def run
        # while the server is accepting clients 
        while (@server_running && client = @server.accept) 
            # puts "^^^^^^ connecting to client number #{@client_count}"

      	    Thread.new client do |client_connection|
              	@client_count += 1
              	current_client = @client_count
                @results = "<p>It's #{Time.now} and we are having some server issues. Be back up soon. Thanks for visiting</p>"
                
                # read request from client and print request length
              	client_data = client_connection.recvfrom(1500)[0].chomp.to_s
                puts "\nclient number: #{current_client}", 
                     "request length: #{client_data.length}",
                     "#{client_data}"

              	# get request data from regex match on client_data
              	# but first set the regex syntax for matching GET requests 
              	get_request_syntax = /(GET) (\/.*?) (\S*)/	
              	client_get_request_match = get_request_syntax.match(client_data)

              	# if regex match was found then process the message
              	if (client_get_request_match)
                		puts "request message: #{client_get_request_match[0]}",
                		     "request type: #{client_get_request_match[1]}",
                		     "request resource: #{client_get_request_match[2]}",
                		     "request format: #{client_get_request_match[3]}"

                		# make sure that resource being requested was not /favicon.ico
                		if !(client_get_request_match[2] =~ /\/favicon.ico/) 
                		    read_data(client_connection, "GET / HTTP/1.0\r\n\r\n")
                        # client_connection.puts @results
                        # client_connection.close
                        print_string = "Message Sent \n" +
                                       "Client Number: #{current_client}<br /> \n" +
                                       "Response Data: #{@results}"
                        puts print_string
                    else
                        client_connection.close
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

