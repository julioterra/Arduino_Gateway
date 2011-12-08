require 'ruport'
require './helpers'

module ArduinoGateway

  module DataRecords
    
    ##########################################################################
    # AbstractRecord - abstract class for all data structure description classes
    class AbstractRecord 
      include ArduinoGateway::Helpers
      
      # method that initializes the class instance variables for all DataRecord classes
      def self.data_attributes *attributes
        attributes = [:id, *attributes]
        attributes.each do |attr|
          attr_accessor attr
          instance_variable_set "@#{attr.to_s}", 0
        end
      end

      # returns that datatables hash list key associated to current DataRecord class
      def self.datatable_key
        self.to_s.match(/([A-Z][a-z]+)([A-Z][a-z]+)\z/)
        variable_name = ":#{$1}_#{$2}s".downcase
        eval ":#{$1}_#{$2}s".downcase
      end

      # returns the ruport datatable associated to current DataRecord
      def self.datatable
        DataActive::DatabaseBuilder.datatables[self.datatable_key]
      end

      # checks if new_record is valid for cur record type
      def self.valid_record?(new_record)
        self.instance_variables.each do |var| 
          return false unless new_record.include? "#{var.to_s.gsub /@/, ''}"           
        end
      end

      # checks if new_record is valid for cur record type
      def self.valid_column?(column_name)
        self.instance_variables.each do |var| 
          return true if column_name.to_s == "#{var.to_s.gsub /@/, ''}"           
        end
        false
      end

      # DONE - new: add a new record into the appropriate database
      # DONE - find_by_xxx: find a record by searching column name xxx
      # delete: delete a record identified by id number 
      def self.method_missing(method_id, *args)
        puts "METHOD MISSING, identifying how to handle method_id: #{method_id}"
        
        if method_id.to_s.match(/find_by_(\S+)/)
          if self.valid_column? $1
            method_id = :rows_with
            args = [{"#{$1}".to_sym => args[0]}]
          end
        end
        
        if self.datatable.respond_to? method_id
          return self.datatable.send(method_id, *args)
        end        
      end


      # method adds new DataRecord to appropriate datatable
      # need to update so that it returns a data Record object with appropriate data
      def initialize (new_record)
        return unless new_record.is_a? Hash
        new_record = keys_to_string(new_record)
        return unless self.class.valid_record? new_record
        self.class.datatable << new_record
        # puts "[AbstractRecord:initialize] Updated Table: #{self.class.datatable_key}",
        #      "#{self.class.datatable.to_text}"
      end
      
    end
    
    # ResourceDevice - implementation of resource device data structure description classes
    class ResourceDevice < AbstractRecord
      data_attributes :name, :ip, :port
    end
    
    # ResourceService - implementation of resource device data structure description classes
    class ResourceService < AbstractRecord
      data_attributes :name
    end

    # ResourceRelationship
    class ResourceRelationship < AbstractRecord
      data_attributes :device_id, :service_id, :post_enabled, :range_max, :range_min, 
    end
    
  end


  module DataActive
  
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
        end
      end
    
      @datatables.each do |key, val|
        puts key
        puts val.to_text
      end

      def self.datatables
        @datatables
      end

      # TEST TEST TEST
      ::ArduinoGateway::DataRecords::ResourceService.new id: 1, name: "test" 
      ::ArduinoGateway::DataRecords::ResourceService.new id: 2, name: "two" 
      ::ArduinoGateway::DataRecords::ResourceService.new id: 3, name: "three" 
      ::ArduinoGateway::DataRecords::ResourceDevice.new id: 1, ip: "0.0.0.0", port: 7999       
      ::ArduinoGateway::DataRecords::ResourceDevice.new id: 2, ip: "0.0.0.0", port: 7888       
      ::ArduinoGateway::DataRecords::ResourceDevice.new id: 2, ip: "0.0.0.0", port: 6777       
      puts ArduinoGateway::DataRecords::ResourceService.as :text
      puts ArduinoGateway::DataRecords::ResourceDevice.as :text
      p ::ArduinoGateway::DataRecords::ResourceService.find_by_id(1).each
      ::ArduinoGateway::DataRecords::ResourceService.find_by_id(1).each do |cur|
        puts "Query ResourceService - record id: #{cur.data["id"]}, name: #{cur.data["name"]}"
      end

    end
  end
  
end
