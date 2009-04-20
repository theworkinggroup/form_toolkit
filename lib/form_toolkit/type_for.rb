module FormToolkit::TypeFor
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::TypeFor::ClassMethods)
      by_class.send(:include, FormToolkit::TypeFor::InstanceMethods)
    end
    
    # == Module Functions ===================================================
    
    def self.type_info(for_class)
      @type_info ||= { }
      
      @type_info[for_class] ||= { }
    end
    
    def self.resolve_type_for(on_class, column)
      # If this is an association, return that class
      if (reflection = on_class.reflect_on_association(column))
        return reflection.klass
      end
      
      # Resolve Paperclip specific definitions, if any
      if (on_class.respond_to?(:attachment_definitions))
        if (definitions = on_class.attachment_definitions)
          if (on_class.attachment_definitions[column])
            return :file
          end
        end
      end
      
      column_found =
        on_class.columns.find do |c|
          c.name.to_sym == column
        end
        
      column_found and column_found.type
    end
  end
  
  module ClassMethods
    def define_type_for(options)
      options.each do |column, type|
        FormToolkit::TypeFor::Extensions.type_info(self)[column.to_sym] = type.to_sym
      end
    end
    
    def resolve_type_for(column)
      FormToolkit::TypeFor::Extensions.resolve_type_for(self, column.to_sym)
    end

    def type_for(column)
      FormToolkit::TypeFor::Extensions.type_info(self)[column] ||=
        resolve_type_for(column)
    end
    
    def field_type(column)
      specified_type = type_for(column)

      case (specified_type)
      when nil:
        case (column)
        when :password, :password_confirmation:
          :password
        else
          :text
        end
      when :boolean:
        :check_box
      when :text:
        :text_area
      when :string:
        :text
      else
        specified_type
      end
    end
  end
  
  module InstanceMethods
    def type_for(column)
      self.class.type_for(column)
    end

    def field_type(column)
      self.class.field_type(column)
    end
  end
end
