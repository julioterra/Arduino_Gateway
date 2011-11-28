require 'ruport'

module ArduinoGateway

  module DataRecords
    
    ##########################################################################
    # RESOURCE - abstract class for all data structure description classes
    class AbstractRecord 
      def self.data_attributes *attributes
        attributes.each do |attr|
          attr_accessor attr
          define_method(attr.to_sym) do
            eval "@#{attr.to_s} = 0"
          end
        end
      end
    end
    
    # RESOURCE DEVICE - implementation of resource device data structure description classes
    class ResourceDevice < AbstractRecord
      data_attributes :ip, :port
    end
    
    # RESOURCE DEVICE - implementation of resource device data structure description classes
    class ResourceService < AbstractRecord
      data_attributes :id, :name
    end

    # # RESOURCE DEVICE - implementation of resource device data structure description classes
    # class ResourceDevice 
    #   attr_accessor :ip, :port
    # end
    # 
    # # RESOURCE DEVICE - implementation of resource device data structure description classes
    # class ResourceService 
    #   attr_accessor :id, :name
    # end
    # 
    # # RESOURCE DEVICE - implementation of resource device data structure description classes
    # class ResourceRelationships
    #   attr_accessor :device_id, :service_id, :post_enabled, :range_max, :range_min, 
    # end
    
  end
  
  ##########################################################################
  # DATABASE_BUILDER - wrapper class for building and managing ruport databases 
  class DatabaseBuilder
    
    DataRecords.constants.each do |record_template|
      unless record_template.equal? :AbstractRecord
      variable_name = "@#{record_template.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase}s"
      record_name = "::ArduinoGateway::DataRecords::#{record_template.to_s}"

      puts "@table_columns = #{record_name}.new.public_methods(false).select! {|cur| !cur.to_s.include?('=')}"
      puts "#{variable_name} = Ruport::Data::Table.new column_names: table_columns"

      eval "@table_columns = #{record_name}.new.public_methods(false).select! {|cur| !cur.to_s.include?('=')}"
      eval "#{variable_name} = Ruport::Data::Table.new column_names: @table_columns"
      eval "puts #{variable_name}.to_text"

      else puts "skipping AbstractRecord"      
      end
    end

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
  # class ActiveDatabase
  #   attr_accessor :resource_devices, :resource_services, :resource_relationships
  #   resource_devices = DatabaseBuilder.new(DataRecords::ResourceDevice.new)
  #   resource_services = DatabaseBuilder.new(DataRecords::ResourceServices.new)
  # end

end

# module ArduinoGateway
#   class ResourceDeviceRecord
#     # data_attributes :ip, :port
#   end
# end