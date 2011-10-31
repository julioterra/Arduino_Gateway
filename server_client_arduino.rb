require 'socket'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

# ip address and host numbers
arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
internet_port_number = 7996
server_running = true

server = TCPServer.new(internet_port_number)  # Socket to listen on port 2000
client_count = 0 
thread_count = 0

# while the server is accepting clients 
while (client = server.accept) 
	client_count += 1
	client_data = client.recvfrom(1500)[0].chomp.to_s
	puts "\nmessage received - length equals = #{client_data.length}"

	Thread.new(client) do |connection|
		input = gets.chomp
		puts input
		if input.contains?("X") then
			puts "got it right to exit"
			exit 
		end
	end

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
			Thread.new(client) do |connection|
				thread_count += 1			
				begin
					socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
					# create an AF_INET address string with the port number and host IP addres
					sockaddr = Socket.pack_sockaddr_in( arduino_port_number, arduino_host_ip )
					# connect to IP address we just packed
					socket.connect( sockaddr )
					# make an HTTP GET request to the arduino
					socket.write( "GET / HTTP/1.0\r\n\r\n" )	
					results = socket.read
					socket.close
				rescue => e
					results ||= "HTTP/1.0 500\r\n\r\n"
					puts "ERROR - Time: #{Time.now}, clients: #{client_count}, threads: #{thread_count}"
					puts "ERROR - Exception Message: #{e.message}, #{e.backtrace}"
				end									
				results += "client_count: #{client_count.to_s} thread_count: #{thread_count.to_s}<br />\n" +
						   "requested resource: #{client_get_request_match[2]}"

				# send the results back to the client on port 7999
				connection.puts results  # Send the time to the client
				# display the results on the terminal
				puts results

				connection.close
			end
		end
	end
end
