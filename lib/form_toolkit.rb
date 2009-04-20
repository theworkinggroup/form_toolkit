module FormToolkit
  autoload(:Helper, 'form_toolkit/helper')
  autoload(:DomElement, 'form_toolkit/dom_element')
  autoload(:DomId, 'form_toolkit/dom_id')
  autoload(:ParamHandler, 'form_toolkit/param_handler')
  autoload(:TypeFor, 'form_toolkit/type_for')
  autoload(:UrlFor, 'form_toolkit/url_for')
  
  def self.framework
    @framework or :jquery
  end
  
  def self.framework=(value)
    @framework = value.to_sym
  end
end
