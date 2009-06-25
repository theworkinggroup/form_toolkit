module FormToolkit::LabelFor
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::LabelFor::ClassMethods)
      by_class.send(:include, FormToolkit::LabelFor::InstanceMethods)
    end
  end
  
  module ClassMethods
    def required_fields(*fields)
      options = (fields.last.is_a?(Hash) and fields.pop or { })
      
      case (fields.length)
      when 0
        @required_fields and @required_fields.keys or [ ]
      else
        @required_fields ||= { }
        
        requirement = true
        
        if (options[:if])
          requirement = options[:if].is_a?(Proc) ? options[:if] : lambda { |o| o.send(options[:if]) }
        elsif (options[:unless])
          requirement = options[:unless].is_a?(Proc) ? options[:unless] : lambda { |o| !o.send(options[:unless]) }
        end
        
        fields.collect(&:to_sym).each do |field|
          @required_fields[field] = requirement
        end
      end
    end
    
    def required_field?(field, instance = nil)
      req = (@required_fields and @required_fields[field])
      
      case (req)
      when Proc
        req.call(instance || self)
      else
        req
      end
    end
    
    def define_label_for(options)
      @label_for ||= { }
      
      options.each do |method, label|
        @label_for[method.to_sym] = label.to_s
      end
    end
    
    def label_for(method)
      @label_for ||= { }
      
      case (method)
      when Array
        key = method.collect { |v| "[#{v}]" }.to_s.to_sym
        label = method.last.to_s.titleize
      else
        key = method.to_sym
        label = method.to_s.titleize
      end
      
      @label_for[key] ||= label
    end
  end
  
  module InstanceMethods
    def label_for(method)
      self.class.label_for(method)
    end

    def required_field?(field)
      self.class.required_field?(field, self)
    end
  end
end
