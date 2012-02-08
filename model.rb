require './model_base'

module ArduinoGateway
  module Model
    
    module ModelTemplates

      # ResourceDevice - implementation of resource device data structure description classes
      class ResourceDevice < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name, :ip, :port
      end

      # ResourceInstance
      class ResourceInstance < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name, :device_id, :service_type_id, :post_enabled, :range_max, :range_min 
      end

      # ResourceService - implementation of resource device data structure description classes
      # consider making this a database of ServiceTypes with: 1. name, 2. id
      class ResourceService < ::ArduinoGateway::Model::AbstractRecord
        database_attributes :name
      end

    end

  end
end