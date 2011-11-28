require 'ruport'

module ArduinoGateway

  ##########################################################################
  # RESOURCE - abstract class for all data structure description classes
  class ResourceRecord 
    def self.data_attributes *attributes
      attributes.each do |attr|
        define_method(attr.to_sym) do; end
      end
    end
  end

  # RESOURCE DEVICE - implementation of resource device data structure description classes
  class ResourceDeviceRecord < ResourceRecord
    data_attributes :ip, :port
  end

  # RESOURCE DEVICE - implementation of resource device data structure description classes
  class ResourceServicesRecord < ResourceRecord
    data_attributes :id, :name
  end

  
  ##########################################################################
  # DATABASE_BUILDER - wrapper class for building and managing ruport databases 
  class DatabaseBuilder
    def initialize(data_struct)
      table_columns = data_struct.public_methods(false)
      table = Ruport::Data::Table.new column_names: table_columns
      puts table.to_text
    end    
    
    def method_missing(method_id, *args)
      if table.respond_to?(method_id) then table.send(method_id, args) 
      else; super; end
    end
  end

  ##########################################################################
  # ACTIVE_DATABASE - class that holds all active databases
  class ActiveDatabase
    attr_accessor :resource_devices, :resource_services, :resource_relationships
    resource_devices = DatabaseBuilder.new(ResourceDeviceRecord.new)
    resource_services = DatabaseBuilder.new(ResourceServicesRecord.new)
  end

end