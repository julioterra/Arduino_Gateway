require 'socket'
require 'open-uri'
require './requests.rb'

module ArduinoGateway
  module Interface

    class ArduinoClient

      class << self
        def register_request(request, timeout=5)
          debug_code = true
          if debug_code then puts "[ArduinoClient/request] - checking if request is RestfulMessage" end

          return -1 unless request.is_a? RestfulRequest
          arduino_connection = make_request (request)  

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
                  if debug_code then puts "[ArduinoClient/request/timer] Connection made, making request, stopping timer" end
                  break
                end
              end
            rescue TimeoutException, Exception => e
              con_thread[:status] = -1
              con_thread[:response] = "<p>Sorry the connection timed out. We are having some server issues. " +
                                      "Be back up soon. Thanks for visiting</p>" +
                                      "<p>It's #{Time.now}.</p>"
              puts "[ArduinoClient/request/timer] ERROR: connection timed out - #{e.request}\n"
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
            puts "[ArduinoClient/request]: response from arduino socket is #{response}" 
          end
          response.to_s
        end
      
        def make_request(request)
          debug_code = true
          # ARDUINO_CONNECTION thread
          # thread responsible for connecting to and captuing response from the arduino
          arduino_connection = Thread.new(request) do |request_data| 
            # use the thread keys to store information about the connection status and the server's response
            Thread.current[:status] = 0
            Thread.current[:response] = ""

            addr = Socket.getaddrinfo(request_data.address[:ip], nil)  
            socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

            if debug_code then puts "[ArduinoClient/request/arduino_connection] - trying to connect\n" end

            begin
              connection_status = socket.connect(Socket.pack_sockaddr_in(request_data.address[:port], addr[0][3]))
              if Thread.current[:status].to_i == 0
                if debug_code then puts "[ArduinoClient/request/arduino_connection] - sending request \n" end
               	socket.write( request_data.restful_request )
               	Thread.current[:response] = Thread.current[:response] + socket.read
                Thread.current[:status] = 1
                socket.close
                Thread.current[:status] = 2
                if debug_code then puts "[ArduinoClient/request/arduino_connection] - response received \n" end
              end
              rescue => e
                puts "[ArduinoClient/request/arduino_connection] ERROR: #{e.request}"
            end
          end
          # arduino_connection
        end

      end # class << self
    end # ArduinoClient class

  end # Interface module
end # ArduinoGateway module