require 'socket'
require 'open-uri'
require './requests.rb'
require './helpers.rb'
require './controller.rb'
require "serialport"

module ArduinoGateway
  module Interface

    class ArduinoClient

      class << self

        def register_controller(controller)
          @controller = controller
        end
        
        def register_request(request, timeout=5)
          debug_code = true
          if debug_code then puts "[ArduinoClient/request] - checking if request is RestfulMessage" end

          return -1 unless request.is_a? RestfulRequest
          if debug_code then puts "[ArduinoClient/request] - starting to time #{Time.now.sec}" end

          arduino_connection = make_request(request)  
          while(arduino_connection[:status].to_i == 0)
          end
          
          response = arduino_connection[:response]
          
          if !arduino_connection.alive? then arduino_connection.terminate end
          
          if debug_code 
            puts "[ArduinoClient/request]: response from arduino socket is #{response}" 
          end
          response.to_s
        end
      
        def make_request(request)
          if request.address[:port] == 0
            arduino_connection = serial_request(request)
          else
            ethernet_request(request)
          end  
        end

        def send_response(response, request)
          puts "******************"
          puts "******************"
          puts "******************"
          puts "from send_response, here is the response: #{response}"
          @controller.register_response response, request
        end

        def serial_request(request)
          arduino_connection = Thread.new(request) do |request|
            Thread.current[:status] = 0
            Thread.current[:response] = ""
            serial_list = `ls /dev/tty.*`.split("\n")
            port_str = serial_list.find{ |n| n.include?("usbserial-A6008kUs") }
            baud_rate, data_bits, stop_bits, parity = 4800, 8, 1, SerialPort::NONE
            puts "Selected Serial Device: #{port_str} from full list: #{serial_list}"

            serial_connection = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
            serial_connection.puts "#{request.restful_request}\r\n\r"
            puts "making serial request: #{request.restful_request}\r\n\r"

            timed_out = false
            timer = ArduinoGateway::Helpers::Timer.get(3) do 
              timed_out = true 
              serial_connection.puts
              serial_connection.close
              # send_response Thread.current[:response], request
              # puts "after send_response"
            end

            while !timed_out do
              if (new_line = serial_connection.gets)
                 Thread.current[:response] = Thread.current[:response] + new_line
              end
            end  
            Thread.current[:status] = 2    
            if timer.alive? then timer.terminate end
          end

        end
        
        def ethernet_request(request)
          # ARDUINO_CONNECTION thread
          # thread responsible for connecting to and captuing response from the arduino
          arduino_connection = Thread.new(request) do |request_data| 
            # use the thread keys to store information about the connection status and the server's response
            Thread.current[:status] = 0
            Thread.current[:response] = ""

            addr = Socket.getaddrinfo(request_data.address[:ip], nil)  
            socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

            timed_out = false
            timer = ArduinoGateway::Helpers::Timer.get(3) do 
              time_out = true
              Thread.current[:status] = -1    
              socket.close
              puts "Closed Socket"
              send_response Thread.current[:response], request
              puts "response sent"
            end
            
            connection_status = socket.connect(Socket.pack_sockaddr_in(request_data.address[:port], addr[0][3]))
            socket.write( request_data.restful_request )

            response = ""
            while !timed_out and new_line = socket.gets do
               response = response + new_line
            end  
            Thread.current[:response] = response
            # Thread.current[:response] = Thread.current[:response] + socket.read
            # send_response(Thread.current[:response].to_s, request)
            
            if !timed_out
              Thread.current[:status] = 2    
              if timer.alive? then timer.terminate end
            end
          end # arduino_connection thread
        end # ethernet_request method

      end # class << self
    end # ArduinoClient class

  end # Interface module
end # ArduinoGateway module