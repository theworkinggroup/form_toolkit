module FormToolkit::DomId
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::DomId::ClassMethods)
      by_class.send(:extend, FormToolkit::DomId::CommonMethods)

      by_class.send(:include, FormToolkit::DomId::InstanceMethods)
      by_class.send(:include, FormToolkit::DomId::CommonMethods)
    end
  end
  
	module ClassMethods
	  def element_name
	    table_name
    end

    def input_name(type)
      "#{class_name.underscore}[#{type}]"
    end

  protected
	  def update_id(separator = ':')
	    ''
    end
  end
  
  module InstanceMethods
	  def element_name
	    self.class.to_s.underscore
    end

    def input_name(type)
      case (type)
      when Array:
        "#{self.class.to_s.underscore}#{type.collect { |n| "[#{n}]" }}"
      else
        "#{self.class.to_s.underscore}[#{type}]"
      end
    end
    
  protected
    def dom_uuid
      @dom_uuid ||= "new_%.0f%03d" % [ Time.now.to_f * 100000, rand(999) ]
    end

	  def update_id(separator = ':')
	    separator + (self.id ? self.id.to_s : dom_uuid)
    end
  end

  module CommonMethods
	  def dom_id=(value)
	    @dom_id = value
	    @separator ||= ':'
    end
	  
		def dom_id(type = nil, separator = ':')
		  @dom_id = nil if (@separator != separator)
			@dom_id ||= element_name + update_id(separator)
			@separator = separator
			
			case (type)
		  when Array:
		    type = type.compact * separator
	    end
			
			FormToolkit::DomElement.new(type.blank? ? @dom_id : "#{@dom_id}#{separator}#{type}")
		end

		def element(type = nil)
		  dom_id.to_js
		end
	end
end
