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
          return false unless request.is_a? RestfulRequest
          make_request(request)  
        end
      
        def make_request(request)
          if request.address[:port] == 0
            serial_request(request)
          else
            ethernet_request(request)
          end  
        end

        def send_response(response, request)
          @controller.register_response response, request
        end


        def serial_request(request)
          arduino_connection = Thread.new(request) do |request|
            begin
              serial_list = `ls /dev/tty.*`.split("\n")
              port_str = serial_list.find{ |n| n.include?("usbserial-A6008kUs") }
              baud_rate, data_bits, stop_bits, parity = 4800, 8, 1, SerialPort::NONE
              response, timed_out, message_complete, serial_connection = "", false, false, ""

              begin
                serial_connection = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
              rescue => e
                raise StandardError, "[ArduinoClient:serial_request] serial port not currently available"
              end
              serial_connection.puts "#{request.restful_request}\r\n\r\n"

              puts "Selected Serial Device: #{port_str} from full list: #{serial_list}"
              puts "Making Serial Request: #{request.restful_request}\r\n\r"

              timer = @controller.timer.new_timer(4) do 
                # if !message_complete
                  timed_out = true 
                  serial_connection.puts
                  serial_connection.close
                # end
              end

              while !timed_out and !message_complete do
                if new_line = serial_connection.gets
                  response = response + new_line 
                  puts new_line
                end
                message_complete = true if response.include? "__END__" 
              end  
              response.gsub!("__END__", "")

            rescue => e
              puts "#{e.message}"
            ensure 
              send_response(response, request)
              serial_connection.close
            end
          end # arduino_connection thread
          arduino_connection
        end # serial_request method
        

        def ethernet_request(request)
          arduino_connection = Thread.new(request) do |request_data| 
            begin
              response, timed_out, message_complete = "", false, false
              socket_addr = Socket.pack_sockaddr_in(request_data.address[:port], request_data.address[:ip])
              socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
              socket.connect(socket_addr)
              socket.write(request_data.restful_request)

              puts
              puts
              puts "[ArduinoClient:ethernet_request] making request #{request_data.restful_request}"
              puts "[ArduinoClient:ethernet_request] making request #{request_data.restful_request}"
              puts "[ArduinoClient:ethernet_request] making request #{request_data.restful_request}"
              puts
              puts

              timer = @controller.timer.new_timer(3) do 
                if !message_complete
                  timed_out = true
                  socket.close             
                end
              end
              
              while !timed_out and new_line = socket.gets do
               response = response + new_line
              end  
              message_complete = true
              
            rescue => e
              puts "[ArduinoClient:ethernet_request] error backtrace #{e}"
            ensure
              send_response(response, request)
              socket.close
            end
          end # arduino_connection thread
          arduino_connection
        end # ethernet_request method

      end # class << self
    end # ArduinoClient class

  end # Interface module
end # ArduinoGateway module