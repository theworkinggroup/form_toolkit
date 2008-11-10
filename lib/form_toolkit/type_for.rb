module FormToolkit::TypeFor
  module Extensions
    # >> Inclusion Hook -----------------------------------------------------

    def self.included(by_class)
      by_class.send(:extend, FormToolkit::TypeFor::ClassMethods)
      by_class.send(:include, FormToolkit::TypeFor::InstanceMethods)
    end
    
    # >> Module Functions ---------------------------------------------------
    
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
      
      definition = on_class.columns.find { |c| c.name.to_sym == column }
      
      definition and definition.type
    end
  end
  
  # >> Extensions to ActiveRecord::Base -------------------------------------
  
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
      case (column)
      when :password, :password_confirmation:
        :password
      else
        case (type_for(column))
        when :text:
          :text_area
        when :file:
          :file
        when :password:
          :password
        when :boolean:
          :check_box
        else
          :text
        end
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
