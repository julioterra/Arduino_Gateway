require 'ruport'

module ArduinoGateway

  module DataRecords
    
    ##########################################################################
    # AbstractRecord - abstract class for all data structure description classes
    class AbstractRecord 
      def self.data_attributes *attributes
        attributes.each do |attr|
          attr_accessor attr
          instance_variable_set "@#{attr.to_s}", 0
        end
      end
    end
    
    # ResourceDevice - implementation of resource device data structure description classes
    class ResourceDevice < AbstractRecord
      data_attributes :ip, :port
    end
    
    # ResourceService - implementation of resource device data structure description classes
    class ResourceService < AbstractRecord
      data_attributes :id, :name
    end

    # ResourceRelationship
    class ResourceRelationship < AbstractRecord
      data_attributes :device_id, :service_id, :post_enabled, :range_max, :range_min, 
    end
    
  end
  
  ##########################################################################
  # DATABASE_BUILDER - wrapper class for building and managing ruport databases 
  class DatabaseBuilder

    @datatables = {}

    DataRecords.constants.each do |record_template|
      unless record_template.equal? :AbstractRecord
      variable_name = "#{record_template.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase}s"
      record_name = "::ArduinoGateway::DataRecords::#{record_template.to_s}"

      create_column_name = "@table_columns = #{record_name}.instance_variables.map!{|c| c.to_s.gsub!(/@/, '')}"
      create_datatable = "@#{variable_name} = Ruport::Data::Table.new column_names: @table_columns"
      add_table_to_array = "@datatables[:#{variable_name}] = @#{variable_name}"

      eval create_column_name
      eval create_datatable
      eval add_table_to_array

      else puts "skipping AbstractRecord"   
      end
    end
    
    @datatables.each do |key, val|
      puts key
      puts val.to_text
    end

    # def method_missing(method_id, *args)
    #   if table.respond_to?(method_id) then table.send(method_id, args) 
    #   else; super; end
    # end
  end

  ##########################################################################
  # ACTIVE_DATABASE - class that holds all active databases
  # class ActiveDatabase
  #   attr_accessor :resource_devices, :resource_services, :resource_relationships
  #   resource_devices = DatabaseBuilder.new(DataRecords::ResourceDevice.new)
  #   resource_services = DatabaseBuilder.new(DataRecords::ResourceServices.new)
  # end

end
