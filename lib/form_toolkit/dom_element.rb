class FormToolkit::DomElement < FormToolkit::Js::Scalar
  DOM_ELEMENT_PROPERTIES = %w(
    attributes
    childNodes
    checked
    className
    clientWidth
    clientHeight
    dir
    firstChild
    id
    innerHTML
    lang
    lastChild
    localName
    namespaceURI
    nextSibling
    nodeName
    nodeType
    nodeValue
    offsetLeft
    offsetParent
    offsetWidth
    offsetHeight
    ownerDocument
    parentNode
    prefix
    previousSibling
    scrollLeft
    scrollTop
    scrollHeight
    scrollWidth
    style
    tabIndex
  ).inject({ }) { |h,v| h[v] = true; h }
  
  def to_js(style = ?')
	  case (FormToolkit.framework)
    when :jquery:
      "$(#{('#' + @value.gsub(/:/, '\\:')).to_js(style)})"
    else
      "$(#{@value.to_js(style)})"
    end
  end
  
  alias_method :dom_id, :to_s
  
protected
  def js_property?(name)
    DOM_ELEMENT_PROPERTIES[name]
  end
end
