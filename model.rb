require './model_base'

module ArduinoGateway
  module Model
    
    module ActiveRecordTemplates

      # ResourceDevice - implementation of resource device data structure description classes
      class ResourceDevice < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name, :ip, :port
      end

      # ResourceRelationship
      class ResourceService < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name, :device_id, :service_type_id, :post_enabled, :range_max, :range_min 
      end

      # ResourceService - implementation of resource device data structure description classes
      # consider making this a database of ServiceTypes with: 1. name, 2. id
      class ResourceRelationship < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name, :service_type_id, :device_id, :service_id
      end

    end

  end
end