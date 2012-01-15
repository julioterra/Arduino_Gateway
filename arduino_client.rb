require 'socket'
require 'open-uri'
require './requests.rb'
require './helpers.rb'
require "serialport"

module ArduinoGateway
  module Interface

    class ArduinoClient

      class << self
        def register_request(request, timeout=5)
          debug_code = true
          if debug_code then puts "[ArduinoClient/request] - checking if request is RestfulMessage" end

          return -1 unless request.is_a? RestfulRequest
          if debug_code then puts "[ArduinoClient/request] - starting to time #{Time.now.sec}" end

          arduino_connection = make_request(request)  
          timer = get_timer(arduino_connection, timeout)            
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
      
        def get_timer(thread, timeout)
          puts "GET TIMER"
          debug_code = true
          thread_return = Thread.new(thread, timeout) do |con_thread, timeout_time|
            start_time = Time.now.sec
            end_time = start_time + timeout_time
            puts "[get_timer] new timer from #{start_time} to #{end_time}"
            
            loop do
              if !(con_thread[:status] == 1 || con_thread[:status] == 2) 
                current_time = Time.now.sec
                # puts "thread running current time: #{current_time} end time: #{end_time}"
                if end_time <= start_time then current_time += 60 end
                if current_time > end_time 
                  con_thread[:status] = -1
                  con_thread[:response] = "<p>Sorry the connection timed out at #{Time.now}."
                  break 
                end
              else
                if debug_code then puts "[ArduinoClient/request/timer] Connection made, making request, stopping timer" end
                break
              end
            end
          end
          thread_return
        end

        def make_request(request)
          if request.address[:port] == 0
            arduino_connection = serial_request(request)
          else
            ethernet_request(request)
          end  
        end

        def serial_request(request)
          arduino_connection = Thread.new(request) do |request|
            Thread.current[:status] = 0
            serial_list = `ls /dev/tty.*`.split("\n")
            port_str = serial_list.find{ |n| n.include?("usbserial-A6008kUs") }
            baud_rate, data_bits, stop_bits, parity = 4800, 8, 1, SerialPort::NONE
            puts "Selected Serial Device: #{port_str} from full list: #{serial_list}"

            serial_connection = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
            serial_connection.puts "#{request.restful_request}\r\n\r"
            puts "making serial request: #{request.restful_request}\r\n\r"

            timed_out = false
            get_new_timer(3) do 
              timed_out = true 
              serial_connection.puts
              serial_connection.close
            end

            # Thread.current[:response] = ""
            response = ""
            while !timed_out do
              if (new_line = serial_connection.gets)
                 response = response + new_line
                 puts new_line if !new_line.empty?
              end
            end  
            # while !timed_out do
            #   # if (new_line = serial_connection.gets)
            #      serial_connection.read(newline)
            #      response = response + new_line
            #      puts new_line
            #   # end
            # end  
            # Thread.current[:response] = response
            Thread.current[:status] = 2    
            # puts Thread.current[:response]          
            puts "done trying to read"
            puts response
          end

        end
        
        def get_new_timer(timeout)
          return unless block_given?
          timer_thread = Thread.new(timeout) do |timeout_time|
            start_time = Time.now.to_i
            end_time = start_time + timeout_time

            puts "[get_timer] timer started from #{start_time} to #{end_time}"        
            loop do
              current_time = Time.now.to_i
              if current_time > end_time
                yield 
                puts "[get timer] timer completed"
                self.terminate
              end
            end
          end
          timer_thread
        end
        # def serial_request(new_request)
          # puts "in serial_request method"
          # arduino_connection = Thread.new(new_request) do |request| 
          #   serial_list = `ls /dev/tty.*`.split("\n")
          #   # puts "List of Serial Devices:", serial_list
          #   port_str = ""
          #   device_found = false
          #   puts "[serial_request] looking for serial device at #{request.address[:ip]}"
          #   serial_list.each do |serial_connection| 
          #     puts "[serial_request] checking connection #{serial_connection}"
          #     if (serial_connection.include?("#{request.address[:ip]}"))
          #       puts "found a connection"
          #       device_found = true
          #       port_str = serial_connection
          #       break
          #     end
          #   end
          #   if device_found
          #     puts "[serial_request] device found #{port_str}"
          #     baud_rate = 9600
          #     data_bits = 8
          #     stop_bits = 1
          #     parity = SerialPort::NONE
          #   
          #     sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
          #     # puts "connecting to #{sp}"
          #     sp.puts request.restful_request
          #     puts request.restful_request
          #     # puts "connecting to #{sp}"
          #     while true do
          #       new_input = sp.read
          #       if !new_input.empty?
          #         puts new_input
          #       end
          #     end
          #   end
          # end
        # end
        
        
        def ethernet_request(request)
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