require 'ruport'
require './helpers'
require './model_helpers'

module ArduinoGateway
  module Models
    
    # AbstractRecord - abstract class for implementations of data structure description classes
    class AbstractRecord 
      include ::ArduinoGateway::Helpers
      include ::ArduinoGateway::Models::ModelHelpers::DatabaseAttributes
      include ::ArduinoGateway::Models::ModelHelpers::RuportDatatable
    end

    # DatabaseBuilder - wrapper class for building and managing ruport databases 
    class DatabaseBuilder
      include ::ArduinoGateway::Models::ModelHelpers::RuportDatabaseBuilder
    end
    
  end # Model module
end # ArduinoGateway module
