module FormToolkit::ParamHandler
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::ParamHandler::ClassMethods)
      by_class.send(:include, FormToolkit::ParamHandler::InstanceMethods)
    end
    
    def self.convert_hash_to_array(hash)
      hash.keys.sort_by(&:to_i).collect do |key|
        hash[key]
      end
    end

    def self.extract_association_params(model_class, params)
      return unless (params)
      
      association_params = { }
      
      model_class.reflections.each do |name, reflection|
        case (reflection.macro)
        when :has_many:
          sub_params = params.delete(name)
          
          # Parameters may be received as model[assoc][0], model[assoc][1]
          if (sub_params.respond_to?(:values))
            sub_params = convert_hash_to_array(sub_params)
          end
          
          if (sub_params)
            association_params[name] = Proc.new do |model|
              sub_params.collect do |build_params|
                model.send(name).build_with_params(build_params)
              end
            end
          end
        when :has_one, :belongs_to:
          if (sub_params = params.delete(name))
            association_params[name] = Proc.new do |model|
              model.send("create_#{name}".to_sym, sub_params)
            end
          end
        end
      end
      
      association_params
    end
  end
  
  # >> -- Extensions to ActiveRecord::Base ----------------------------------
  
  module ClassMethods
    def build_with_params(params, privilege_level = nil)
      association_params = FormToolkit::ParamHandler::Extensions.extract_association_params(self, params)
      
      model = new(params)
      
      if (association_params)
        association_params.each do |name, proc|
          proc.call(model)
        end
      end
      
      model
    end
  end
  
  module InstanceMethods
    # FUTURE: Add 'restriction level' support
    def update_with_params(params, privilege_level = nil)
      association_params = FormToolkit::ParamHandler::Extensions.extract_association_params(self.class, params)
  
      update_attributes(params)
      
      association_params.each do |name, proc|
        proc.call(self)
      end
    end

    def update_with_params!(params)
      update_with_params(params)
      self.save!
    end
  end
end
