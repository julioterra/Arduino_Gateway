require 'socket'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

# ip address and host numbers
arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
public_port_number = 7996
server_running = true

server = TCPServer.new(public_port_number)  # Socket to listen on port 2000
client_count = 0 
thread_count = 0

# create a thread to listen to keyboard commands
Thread.new(server) do |servidor|
	while(server_running)
		input = gets.chomp
		puts "processing your input [#{input}]"
		if input.include?("X") then
			puts "closing port #{public_port_number} and exiting app..."
			server_running = false
			servidor.close
			exit 
		end
	end
end

# while the server is accepting clients 
while (server_running && client = server.accept) 
	client_count += 1
	client_data = client.recvfrom(1500)[0].chomp.to_s
	puts "\nmessage received - length equals = #{client_data.length}"

	# regex syntax for matching GET requests 
	get_request_syntax = /(GET)\s(\/.*?)\s(\S*)/	
	# get request data from regex match on client_data
	client_get_request_match = get_request_syntax.match(client_data)

	# if regex match was found then process the message
	if (client_get_request_match)
		puts "request message: #{client_get_request_match[0]}"
		puts "request type: #{client_get_request_match[1]}"
		puts "request resource: #{client_get_request_match[2]}"
		puts "request format: #{client_get_request_match[3]}"
		
		# make sure that resource being requested was not /favicon.ico
		if !(client_get_request_match[2] =~ /\/favicon.ico\z/) 
			puts "GOTHERE"
			
			
  			Thread.new client do |connection|
  				puts "thread starting"
  				thread_count += 1	
  				time_now = Time.now		
          results = "It's #{time_now} and we are having some server issues. Be back up soon."
          arduino_host_ip = '192.168.2.200'
          arduino_port_number = 7999

          socket = Socket.new( AF_INET, SOCK_STREAM, 0 )        
        	# create an AF_INET address string with the port number and host IP addres
        	sockaddr = Socket.pack_sockaddr_in( arduino_port_number, arduino_host_ip )
        	# connect to IP address we just packed
  				begin
          	if (socket.connect( sockaddr ) == 0)
            	  # make an HTTP GET request to the arduino
              	socket.write( "GET / HTTP/1.0\r\n\r\n" )
            	  puts "socket.write( 'GET \/ HTTP\/1.0' )"
              	results = socket.read
            	  puts "socket.read"
                socket.close
        				results += "client_count: #{client_count.to_s} thread_count: #{thread_count.to_s}<br />\n" +
        						       "requested resource: #{client_get_request_match[2]}"            	
            else
              results = "Data not available" +
                        "client_count: #{client_count.to_s} thread_count: #{thread_count.to_s}<br />\n" +
                						       "requested resource: #{client_get_request_match[2]}"  
            end
          rescue
        	  puts "RESCUE: #{results}"
          
          end          

      		# send the results back to the client on port 7999
  				connection.puts results  # Send the time to the client
  				# display the results on the terminal
  				puts "final message sent: #{results}"
  				connection.close
  				
  			end
			
		end
	end
end
