require './model_base'

module ArduinoGateway
  module Models
    module ModelHelpers

      module DatabaseAttributes
        ##################
        # class methods
        def self.included(base)
          base.send :extend, ClassMethods
        end
      
        # ClassMethods = Module.new do 
        module ClassMethods  
          def database_attributes *attributes
            attributes = [:id, *attributes]
            attributes.each do |attr|
              if attr.is_a? Symbol 
                send :attr_accessor, attr
                instance_variable_set "@#{attr.to_s}", 0
              end
            end

            # puts "adding new table from database_attributes #{self}"
            ::ArduinoGateway::Models::DatabaseBuilder.build_datatable self
          end
        end
      end
  
      module RuportDatabaseBuilder
        ##################
        # class methods
        def self.included(base)
          base.send :extend, ClassMethods
          base.send :datatables
        end
      
        module ClassMethods  
          def datatables
            @datatables ||= {}
          end
          def build_datatables
            ::ArduinoGateway::Models::Model.constants.each do |record_template|
              unless record_template.equal? :AbstractRecord
                self.build_datatable(record_template)
              end
            end
          end

          def build_datatable(record_template)
            variable_path = record_template.to_s.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
            variable_name = variable_path.to_s.gsub(/([:|.|a-z|A-Z|_]*)::([a-z|A-Z|_]*)[.|a-z|A-Z|_]*\z/, "\\2") + "s"
            instance_variable_set "@table_columns", eval("#{record_template}.instance_variables.map!{|c| c.to_s.gsub!(/@/, '')}")
            instance_variable_set "@#{variable_name.to_s}", eval("Ruport::Data::Table.new column_names: @table_columns")
            @datatables[variable_name.to_sym] = eval("@#{variable_name.to_s}")
            puts
            puts "NEW TABLE named #{variable_name.to_sym}, structure:"
            puts @datatables[variable_name.to_sym].to_s
            puts
          end
        end      
      end
    
      module RuportDatatable
        ##################
        # instance methods
        def initialize (new_record)
          return unless new_record.is_a? Hash
          new_record[:id] = 0;
          new_record = keys_to_string(new_record)
          return unless self.class.valid_record? new_record
          new_record["id"] = self.class.id_next;
          self.class.datatable << new_record
          create_methods(new_record)
          puts
          puts "NEW RECORD in #{self.class.to_s}, datatable:"
          puts self.class.as :text
          puts
          super
        end
    
        def create_methods(new_record)
          new_record = keys_to_string(new_record)
          return false unless self.class.valid_record? new_record
          new_record.each do |key, val|
            instance_variable_set "@#{key}", val 
            send :define_singleton_method, key.to_sym do
              instance_variable_get "@#{key}"
            end
            send :define_singleton_method, "#{key}=".to_sym do |val|
              instance_variable_set "@#{key}", val 
            end
          end
          true
        end
    
        ##################
        # class methods
        def self.included(base)
          base.send :extend, ClassMethods
        end
    
        module ClassMethods
          attr_accessor :id
          def id_next
            @id = @id + 1
          end

          # returns that datatables hash list key associated to current DataRecord class
          def datatable_key
            self.to_s.match(/([A-Z][a-z]+)([A-Z][a-z]+)\z/)
            variable_name = ":#{$1}_#{$2}s".downcase
            eval ":#{$1}_#{$2}s".downcase
          end

          # returns the ruport datatable associated to current DataRecord
          def datatable
            ::ArduinoGateway::Models::DatabaseBuilder.datatables[datatable_key]
          end

          # checks if new_record is valid for cur record type
          def valid_record?(new_record)
            instance_variables.each do |var| 
              return false unless new_record.include? "#{var.to_s.gsub /@/, ''}"           
            end
          end

          # checks if new_record is valid for cur record type
          def valid_column?(column_name)
            instance_variables.each do |var| 
              return true if column_name.to_s == "#{var.to_s.gsub /@/, ''}"           
            end
            false
          end

          # enables using standard Ruport methods with any RuportDatatable
          def method_missing(method_id, *args)
            if method_id.to_s.match(/find_by_(\S+)/)
              if valid_column? $1
                method_id = :rows_with
                args = [{"#{$1}".to_sym => args[0]}]
              end
            end
            if datatable.respond_to? method_id; return datatable.send method_id, *args
            else; super
            end        
          end
        end
      end
    
    end # ModelHelpers module
  end # Model module
end # ArduinoGateway module