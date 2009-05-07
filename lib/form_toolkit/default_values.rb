module FormToolkit::DefaultValues
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::DefaultValues::ClassMethods)
      by_class.send(:extend, FormToolkit::DefaultValues::CommonMethods)

      by_class.send(:include, FormToolkit::DefaultValues::InstanceMethods)
      by_class.send(:include, FormToolkit::DefaultValues::CommonMethods)
    end
  end
  
	module ClassMethods
	  def define_defaults_for(hash)
	    new_default_values = HashWithIndifferentAccess.new
	      
	    new_default_values.merge!(@default_values) unless (@default_values.blank?)
	    new_default_values.merge!(hash) unless (hash.blank?)

	    @default_values = new_default_values.freeze
    end
    alias_method :default_values=, :define_defaults_for
    
    def default_values(model = nil, hash = nil, overrides = nil)
      @default_values ||= HashWithIndifferentAccess.new.freeze
      
      return @default_values if (!model and !hash and !overrides)
      
	    combined = @default_values

      if (superclass.respond_to?(:default_values))
        combined = superclass.send(:default_values, model, @default_values, overrides)
      end
      
      # Priority order (lowest to highest): @default_values, hash, overrides
      combined = hash.blank? ? combined : combined.merge(hash)
      combined = overrides.blank? ? combined : combined.merge(overrides)
      
      # EXPERIMENTAL: Proc method to assign default value
      combined.inject(HashWithIndifferentAccess.new) do |h, (k,v)|
        case (v)
        when Proc
          if (model)
            h[k] = v.call(model)
          end
        else
          h[k] = v
        end

        h
      end
    end
    
    def build_with_defaults(params = nil, overrides = nil)
      model = new
      
      model.attributes = default_values(model, params, overrides)
      
      model
    end

    def create_with_defaults(params = nil, overrides = nil)
      model = build_with_defaults(params, overrides)
      
      model.save
      
      model
    end

    def create_with_defaults!(params = nil, overrides = nil)
      model = build_with_defaults(params, overrides)
      
      model.save!
      
      model
    end
  end
  
  module InstanceMethods
    def default_values(model = nil, hash = nil, overrides = nil)
      self.class.default_values(self, hash, overrides)
    end

    def assign_default_values
      self.default_values.each do |k, v|
        write_attribute(k, v) if (read_attribute(k).blank?)
      end
    end
  end

  module CommonMethods
	end
end
