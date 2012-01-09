require 'ruport'
require './helpers'
require './model_helpers'

module ArduinoGateway
  module Model
    
    # AbstractRecord - abstract class for implementations of data structure description classes
    class AbstractRecord 
      include ::ArduinoGateway::Helpers
      include ::ArduinoGateway::Model::ModelHelpers::DatabaseAttributes
      include ::ArduinoGateway::Model::ModelHelpers::RuportDatatable
    end

    # DatabaseBuilder - wrapper class for building and managing ruport databases 
    class DatabaseBuilder
      include ::ArduinoGateway::Model::ModelHelpers::RuportDatabaseBuilder
    end
    
  end # Model module
end # ArduinoGateway module
