module ArduinoGateway
  module Control
    module ControlHelpers
      
      def get_service_id(service_type_name)
        if new_service?(service_type_name)
          new_service = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceService.new name: service_type_name
          new_service.id = check_service_id(service_type_name)
        else
          check_service_id(service_type_name)
        end
      end
      
      def check_service_id(service_type_name)
        temp_records = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceService.find_by_name(service_type_name)
        if temp_records.length > 0; return temp_records[0].id.to_i
        else; return get_new_service_id; end        
      end

      def get_new_service_id
        sorted_database = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceService.sort_rows_by "id" 
        service_id_cat_number_temp = 0
        if sorted_database.length > 0
          sorted_database.each do |record|
            if service_id_cat_number_temp < record.id.to_i
              service_id_cat_number_temp = record.id.to_i
            end
          end
          service_id_cat_number_temp = service_id_cat_number_temp + 1       
        end       
      end
      
      def new_service?(service_type_name)
        sorted_database = ::ArduinoGateway::Model::ActiveRecordTemplates::ResourceService.sort_rows_by "name" 
        if sorted_database.length > 0
          sorted_database.each do |record|
            record = record.as :text
            if record.downcase.include? service_type_name
              # puts "match found - #{record.as :text}"
              return false
            end
          end
        end  
        true             
      end

    end # ControllerHelpers module
  end # Controller module
end # ArduinoGateway module