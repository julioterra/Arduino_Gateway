require 'socket'
require 'open-uri'
require './requests.rb'
require './arduino_client.rb'
require './public_server.rb'
require './controller.rb'

class PublicServer 
    attr_accessor :arduino_list, :debug_code, :server_running

    def initialize (public_port)
        puts "[PublicServer:new] ******************************"
        puts "[PublicServer:new] starting up the PublicServer"

        # ip address and host numbers
        @public_port_number = public_port.to_i
        @connections = {}
        @debug_code = true      
        @client_count = 0
        @controller = -1

        # start public server in a block to capture any issues associated 
        # with the connection.
        begin        
            @server = TCPServer.new(@public_port_number)  
            @server_running = true
          rescue => e
            puts "[PublicServer:new] RESCUE: error with public server #{e.message}"
        end
                      
        puts "[PublicServer:new] start up completed"
        puts "[PublicServer:new] ******************************"
    end
    
    def register_controller(controller)
        @controller = controller
    end
    
    def run(controller=@controller)
        unless controller.is_a? ArduinoController ; return ; end
        debug_code = true
        if debug_code ; puts "[PublicServer:run] starting to run - server status: #{@server_running}" ; end

        @controller = controller
        # while the server is accepting clients 
        while (@server_running && client = @server.accept) 
          	@client_count += 1
            # add new thread to the connections hash, 
            # where it is stored based on id number
            @connections.merge!({@client_count => client})
            if debug_code ; puts "[PublicServer:run] create new connection: #{p @connections}" ; end

            # create a new thread to handle each incoming client request
            # first increment the client count by one (this is used to set the current client id)
      	    connection = Thread.new client, @client_count do |client_connection, client_count|
              	Thread.current[:id] = client_count
                # Thread.current[:client_connection] = client_connection
                if debug_code ; puts "[PublicServer:run] NEW client ID: #{Thread.current[:id]}" ; end
                
                # read request from client and print the content's length
              	client_request = client_connection.recvfrom(1500)[0].chomp.to_s
                if debug_code ; puts "[PublicServer:run] request length: #{client_request.length}" ; end

                # register request, along with id, with the controller
                client_connection.puts @controller.register_request(client_request, Thread.current[:id])
            end
        end
    end
    
    # callback method used by controller to respond to requests with data from the arduinos
    def respond (response, id)
      if debug_code ; puts "[PublicServer:respond] id: #{id}, response empty? #{response.empty?}" ; end
      
      @connections[id].puts response unless response.empty?
      @connections[id].close   
      @connections.delete(id)   

    end
    
    def stop
      @server_running = false
			@server.close 
			exit
    end
       
end