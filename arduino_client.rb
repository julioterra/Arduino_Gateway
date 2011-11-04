require 'socket'
require 'open-uri'
require './requests.rb'
# include Socket::Constants

class ArduinoClient

    def initialize(message="", timeout=2)
      # request(message) if message.is_a? RestfulRequest
      # else
      #     # holds current connection status with an Arduino
      #     #  -1 = connection unavailable
      #     #   0 = establishing connection
      #     #   1 = connection established
      #     #   2 = connection completed
      #     # connection_status = 0
      # end
    end
    
    def self.request(message, timeout=2)
        debug_code = true
        if debug_code then puts "[ArduinoClient/request] - checking if message is RestfulMessage\n#{message.full_request}" end

        return -1 unless message.is_a? RestfulRequest
        message = message
        if debug_code then puts "[ArduinoClient/request] - starting to process message\n" end
    
    
        # ARDUINO_CONNECTION thread
        # thread responsible for connecting to and captuing response from the arduino
        arduino_connection = Thread.new(message) do |request_data| 
            # use the thread keys to store information about the connection status and the server's response
            Thread.current[:status] = 0
            Thread.current[:response] = 0

            addr = Socket.getaddrinfo(request_data.address[:ip_host], nil)  
            socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

            if debug_code then puts "[ArduinoClient/request/arduino_connection] - trying to connect\n" end

            begin
                connection_status = socket.connect(Socket.pack_sockaddr_in(request_data.address[:port], addr[0][3]))
                if Thread.current[:status].to_i == 0
                    Thread.current[:status] = 1
                    if debug_code then puts "[ArduinoClient/request/arduino_connection] - about to request \n" end
                   	socket.write( "GET / HTTP/1.0\r\n\r\n" )
                   	Thread.current[:response] = socket.read
                    socket.close
                    Thread.current[:status] = 2
                    if debug_code then puts "[ArduinoClient/request/arduino_connection] - message read \n" end
                end
              rescue => e
                  puts "[ArduinoClient/request/arduino_connection] ERROR: \n #{e.message} \n#{e.backtrace}"
            end
        end


        if debug_code then puts "[ArduinoClient/request] - starting to time #{Time.now.sec}" end
        # TIMER thread
        # thread responsible ending the connection attempt after a pre-specified timeout
        ######## save this as a proc or lambda
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
                      if debug_code then puts "[ArduinoClient/request/timer] Timer: stopping thread loop : status #{con_thread[:status]}" end
                      break
                    end
                end
             rescue TimeoutException, Exception => e
                con_thread[:status] = -1
                con_thread[:response] = "<p>Sorry the connection timed out. We are having some server issues. " +
                                        "Be back up soon. Thanks for visiting</p>" +
                                        "<p>It's #{Time.now}.</p>"
                puts "[ArduinoClient/request/timer] ERROR: connection timed out - #{e.message}\n"
            end
         end
            
        while(arduino_connection[:status].to_i == 0 || arduino_connection[:status].to_i == 1)
        end
      
        # puts "set response with arduino_connection #{arduino_connection[:response]}"
        response = arduino_connection[:response]
        # puts "response set with arduino_connection #{response}"
      
        if !timer.alive? then timer.terminate end
        if !arduino_connection.alive? then arduino_connection.terminate end

        if debug_code 
          puts "***[ArduinoClient/request]: returning data from arduino socket" 
        end
        response
    end

end