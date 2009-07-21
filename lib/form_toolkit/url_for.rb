module FormToolkit::UrlFor
  def self.default_controller_namespace
    @default_controller_namespace
  end

  def self.default_controller_namespace=(value)
    @default_controller_namespace = value
  end
  
  module Extensions
    def self.included(by_class)
      by_class.send(:extend, FormToolkit::UrlFor::ClassMethods)
      by_class.send(:include, FormToolkit::UrlFor::InstanceMethods)
    end
  end
  
  # >> -- Extensions to ActiveRecord::Base ----------------------------------
  
  module ClassMethods
    def controller_namespace
      # Namespace may be defined or set specifically to false, which is
      # equivalent to forcing no namespace. A nil value means to use the
      # default namespace.

      (!defined?(@controller_namespace) or @controller_namespace.nil?) ?
        FormToolkit::UrlFor.default_controller_namespace :
        @controller_namespace
    end

    def controller_namespace=(value)
      @controller_namespace = value
    end
    
    def controller_for
      @controller_for ||= 
        case (with_namespace = controller_namespace)
        when nil, false
          table_name
        else
          with_namespace.to_s + '/' + table_name
        end
    end
    
    def controller_for=(value)
      @controller_for = value
    end
    
    def url_for_options
      nil
    end

    def url_for(action = :index, options = { })
      # Map instance actions to class-level actions
      case (action)
      when :show
        action = :index
      when :update
        action = :create
      end
      
      url_params = {
        :controller => controller_for,
        :action => action.to_s
      }
      
      if (_options = url_for_options)
        url_params.merge!(url_for_options)
      end
      
      url_params.merge(options)
    end
  end
  
  module InstanceMethods
    def url_for_options
      nil
    end

    def url_for(action = nil, options = { })
      if (action.is_a?(Hash))
        options = action
        action = nil
      end
      
      url_params =
        self.new_record? ?
          {
            :controller => self.class.controller_for,
            :action => (action || :create).to_s
          } :
          {
            :controller => self.class.controller_for,
            :action => (action || :show).to_s,
            :id => self.to_param
          }

      if (_options = url_for_options)
        url_params.merge!(url_for_options)
      end
      
      url_params.merge(options)
    end
  end
end
