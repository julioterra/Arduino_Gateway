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

# thread 


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

current_t = 0

def connect_to(host, port, timeout=nil, socket_client)
	time_start = "#{Time.now}"		
  results = "It's #{time_start} and we are having some server issues. Be back up soon."
  addr = Socket.getaddrinfo(host, nil)
  socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
  waiting_for_data = true

  timer = Thread.new(socket, socket_client) do |connection, client_connection|
      puts "THREAD"
      start_time = Time.now.sec
      end_time = start_time + 3
      current_time = Time.now.sec
      if current_time < start_time then current_time += 60 end
      puts "before loop #{start_time}, #{end_time}"
      begin
          loop do
            current_time = Time.now.sec
            if current_time < start_time then current_time += 60 end
            if current_time > end_time 
              puts "done waiting"
              connection.close
              client_connection.puts results
              client_connection.close
              puts "port closed"
              raise Exception, "too much time" 
            end
          end
       rescue Exception => e
          time_end = Time.now
          connection.close
          client_connection.puts results
          client_connection.close
          puts "Error Messages: start time: #{time_start}, end time: #{time_end}\n#{e.message}, #{e.backtrace}"
      end
   end

  # begin
  connection_status = socket.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
  if (connection_status == 0)
    socket
    puts "socket connected"
    # make an HTTP GET request to the arduino
  	socket.write( "GET / HTTP/1.0\r\n\r\n" )
    puts "socket.write( 'GET \/ HTTP\/1.0' )"
  	results = socket.read
    puts "socket.read"
    waiting_for_data = false
    socket.close
    timer.kill
  end
  results
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
			
  			Thread.new client do |connection|
  				puts "thread starting"
  				thread_count += 1	
  				time_now = "#{Time.now}"		
          results = "It's #{time_now} and we are having some server issues. Be back up soon."
          arduino_host_ip = '192.168.2.200'
          arduino_port_number = 7999
				  results = connect_to(arduino_host_ip, arduino_port_number, 5, connection)
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
