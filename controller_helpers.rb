module ArduinoGateway
  module Controller
    module ControllerHelpers

      # module ServiceTypeControls
        def get_service_type_id (service_type_name)
          temp_records = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceRelationship.find_by_name(service_type_name)
          if temp_records.length > 0; return temp_records[0].service_type_id.to_i
          else; return get_new_service_type_id || 0; end        
        end

        def get_new_service_type_id
          sorted_database = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceRelationship.sort_rows_by "service_type_id" 
          service_id_cat_number_temp = 0
          if sorted_database.length > 0
            sorted_database.each do |record|
              if service_id_cat_number_temp < record.service_type_id.to_i
                service_id_cat_number_temp = record.service_type_id.to_i
              end
            end
            service_id_cat_number_temp = service_id_cat_number_temp + 1       
          end       
        end
      # end # ServiceTypeControls module

    end # ControllerHelpers module
  end # Controller module
end # ArduinoGateway module