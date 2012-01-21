require './helpers.rb'
require './requests.rb'
require "serialport"

new_request = ::ArduinoGateway::RestfulRequest.new(-1, "GET /json\r\n\r\n ", ip:"usbserial-A6008kUs", port: 0)

arduino_connection = Thread.new(new_request) do |request|
  Thread.current[:response] = ""
  serial_list = `ls /dev/tty.*`.split("\n")
  port_str = serial_list.find{ |n| n.include?("usbserial-A6008kUs") }
  baud_rate, data_bits, stop_bits, parity = 4800, 8, 1, SerialPort::NONE
  puts "Selected Serial Device: #{port_str} from full list: #{serial_list}"

  serial_connection = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
  serial_connection.puts "#{request.restful_request}\r\n\r"
  puts "making serial request: #{request.restful_request}\r\n\r"

  timed_out = false
  # timer = ArduinoGateway::Helpers::Timer.get(3) do 
  #   puts "setting timed_out to true"
  #   timed_out = true 
  #   serial_connection.puts
  #   serial_connection.close
  # end

  response = ""
  while !timed_out do
    if response = serial_connection.gets
      Thread.current[:response] = Thread.current[:response].to_s + response
      puts response
    end
  end  
  puts Thread.current[:response]
  
end # arduino_connection thread

arduino_connection.join

loop do
end