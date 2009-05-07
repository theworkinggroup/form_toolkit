require 'form_toolkit/core_extensions'
require 'form_toolkit'

require 'form_toolkit/dom_id'
require 'form_toolkit/label_for'
require 'form_toolkit/type_for'
require 'form_toolkit/url_for'

require 'active_record'

class ActiveRecord::Base
  include FormToolkit::DefaultValues::Extensions
  include FormToolkit::DomId::Extensions
  include FormToolkit::ParamHandler::Extensions
  include FormToolkit::LabelFor::Extensions
  include FormToolkit::TypeFor::Extensions
  include FormToolkit::UrlFor::Extensions
end
