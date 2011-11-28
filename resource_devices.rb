require 'ruport'

module ArduinoGateway
  class Resource 
    attr_accessor :ip, :port
  end

  class ResourceDevice < Resource
    attr_accessor :ip, :port
  end

  class DataTable
    # initialize(data_struct)
    #   table_columns = data_struct.instance_variables
    #   table = Ruport
    # end
  end

end
