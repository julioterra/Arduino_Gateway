puts "\n\n\n**********************************"
puts "** server_client_arduino_starting"

require 'socket'
require 'open-uri'
# require './requests.rb'
# require './arduino_client.rb'
require './public_server.rb'
require './model.rb'
require './controller.rb'
include Socket::Constants
include ArduinoGateway::Model

# create a thread for the server
# on main app look for a key stroke to quite the server

class TimeoutException < Exception 
end

arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
public_port_number = 8043

arduino_server = ArduinoGateway::PublicServer.new(public_port_number)
controller = ArduinoGateway::Controller::MainController.new(arduino_server)
arduino_server.run()

