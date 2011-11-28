require 'socket'
require 'open-uri'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './controller.rb'

module ArduinoGateway

  # PublicServer is responsible for handling clients connections, reading client requests 
  # and passing on those requests to a controller for processing
  class PublicServer 
      attr_accessor :server_running, :public_port_number

      def initialize (public_port)
          # initialize the port number, connection hash, and client count
          @public_port_number = public_port.to_i
          @connections = {}
          @client_count = 0

          # when debug_code variable is set to true server will print debug messages to terminal
          @debug_code = true      

          # start public server in a block to capture any issues associated with connection.
          begin        
              @server = TCPServer.new(@public_port_number)  
              @server_running = true
            rescue => e
              puts "[PublicServer:new] ERROR: not able to start up TCP Server #{e.message}"
          end
                      
          if @debug_code; puts "[PublicServer:initialize] PublicServer initialized"; end
      end
    

      # register controller with public server; controller must include a callback method
      # called register_public_request.
      def register_controller(controller)
          @controller = controller
      end
    
    
      # run the public_server; method responsible for accepting new clients, reading
      # client requests and registering those requests with the controller.
      def run()
          unless @controller.respond_to?(:process_public_request) 
              puts "[PublicServer:run] ERROR: controller does not have register_public_request callback method"            
              return
          end
  
          if @debug_code
              puts "[PublicServer:initialize] PublicServer listening to port #{@public_port_number}"
          end
  
          # while the server is accepting clients 
          while (client = @server.accept) 
              # update the client_count variable
            	@client_count += 1            	
              if @debug_code; puts "[PublicServer:run] ID: #{@client_count}, new client at socket: #{client} "; end

              # create a new thread to handle each incoming client request
        	    connection = Thread.new client, @client_count do |client_connection, client_count|
                  Thread.current[:client] = client_connection             
                	client_request = client_connection.recvfrom(2000)[0].chomp.to_s
                  @controller.process_public_request(client_request, client_count)
              end
              
              # add thread to the connections hash list
              @connections.merge!({@client_count => connection})                 
          end
      end
    

      # callback method used by controller to respond to client requests once data 
      # is received from the arduinos
      def respond(response, id)
        @connections[id][:client].puts response unless response.empty?
        stop(id)
      end
    

      # method that kills client connections from @connections hash list and turns 
      # off  server if no connection id is provided.
      def stop(id = -1)
          if id == -1 
              @server.close 
              @server_running = false
    			else
              @connections[id][:client].close   
              @connections[id].kill   
              @connections.delete(id)   
  			  end
      end
       
  end

end