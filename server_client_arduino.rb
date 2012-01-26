puts "\n\n\n**********************************"
puts "** server_client_arduino_starting"

require 'socket'
require 'open-uri'
require './public_server.rb'
require './model.rb'
require './controller.rb'
include Socket::Constants
include ArduinoGateway::Model

public_port_number = 7996

if ARGV[0] 
  public_port_number = ARGV[0] 
end

arduino_server = ArduinoGateway::Interface::PublicServer.new(public_port_number)
arduino_controller = ArduinoGateway::Control::Controller.new(arduino_server)
arduino_server.run()

