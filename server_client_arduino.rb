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

class TimeoutException < Exception 
end

def connect_to(host, port, socket_client, timeout=2)
  results = "It's #{Time.now} and we are having some server issues. Be back up soon."
  addr = Socket.getaddrinfo(host, nil)  
  socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

  timer = Thread.new(socket, socket_client) do |connection, client_connection|
      start_time = Time.now.sec
      end_time = start_time + timeout
      current_time = Time.now.sec
      if current_time < start_time then current_time += 60 end
      # puts "before loop #{start_time}, #{end_time}"
      begin
          loop do
            current_time = Time.now.sec
            if current_time < start_time then current_time += 60 end
            if current_time > end_time then raise TimeoutException, "Timer exceeded time limit. Raising TimeoutException." end
          end
       rescue TimeoutException => e
          client_connection.puts results
          connection.close
          client_connection.close
          puts "Error Rescue: ports closed and exceptions results sent.\n"
          puts "Error Message: #{e.message},", e.backtrace
      end
   end

  connection_status = socket.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
  if (connection_status == 0)
    timer.kill
    socket
  else
    nil
  end
end


# while the server is accepting clients 
while (server_running && client = server.accept) 
	client_count += 1
	client_data = client.recvfrom(1500)[0].chomp.to_s
	puts "\nrequest length: #{client_data.length}"

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
			
  			Thread.new client do |connection|
  				thread_count += 1	
          results = "It's #{Time.now} and we are having some server issues. Be back up soon."
				  socket = connect_to(arduino_host_ip, arduino_port_number, connection)
          if (socket)
          	socket.write( "GET / HTTP/1.0\r\n\r\n" )
          	results = socket.read
            socket.close
          end			  

  				results += "client_count: #{client_count.to_s} thread_count: #{thread_count.to_s}<br />\n" +
  						       "requested resource: #{client_get_request_match[2]}"      

      		# send the results back to the client on port 7999
  				connection.puts results  # Send the time to the client
  				connection.close

  				# display the results on the terminal
  				puts "final message sent: \n#{results}"
  				
  			end
			
		end
	end
end
