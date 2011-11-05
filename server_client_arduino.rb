require 'socket'
require 'open-uri'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './controller.rb'
include Socket::Constants

# create a thread for the server
# on main app look for a key stroke to quite the server

class TimeoutException < Exception 
end

arduino_host_ip = '192.168.2.200'
arduino_port_number = 7999
public_port_number = 7996

# ALTERNATE WAY TO GET DATA FROM ARDUINO 
# arduino_page = open("http://192.168.2.200:7999/")
# puts "**************************" +
#      "here is the test page content: \n"
# p arduino_page.read  # returns main content 
# p arduino_page.meta  # returns content type

arduino_server = PublicServer.new(public_port_number)
controller = ArduinoController.new(arduino_server)
controller.register_arduino({name: "worktable", content: {ip: arduino_host_ip, port: arduino_port_number}})
arduino_server.run()

