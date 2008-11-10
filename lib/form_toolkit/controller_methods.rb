module FormToolkit::ControllerMethods
  # >> Inclusion Hook -----------------------------------------------------

  def self.included(by_class)
    by_class.send(:extend, FormToolkit::ControllerMethods::ClassMethods)
    by_class.send(:include, FormToolkit::ControllerMethods::InstanceMethods)
  end
  
  module ClassMethods
    def handles_resource(type, options)
      # TODO
    end
  end
  
  module InstanceMethods
  end
end
