module FormToolkit::Helper
  def hidden_fields_for_params(*list)
    if (list.empty?)
      list = params.keys - [ :controller, :action ]
    end

    list.flatten.collect do |key|
      hidden_field_tag(key, params[key])
    end
  end

  def form_helper(model, options = { }, &block)
    options[:url] ||= model.url_for
    
    style = nil
    
    [ :live, :ajax, :submit ].each do |key|
      if (options.delete(key))
        style = key
      end
    end
    
    options[:method] ||= :put unless (model.new_record?)
    
    case (style)
    when :live:
      yield(FormToolkit::Generator::LiveEdit.new(self, model, options))
    when :ajax, :submit:
      # FUTURE: Reconcile difference between HTML options and form_remote_tag options
      form_options = {
        :url => (options.delete(:url) or model.url_for(method)),
        :html => options
      }
      
      generator = FormToolkit::Generator::AjaxSubmit.new(self, model)
      
      form_remote_tag(form_options) do
        puts generator.dom_id_field
        yield(generator)
      end
    else
      url = options.delete(:url)
      generator = FormToolkit::Generator::Basic.new(self, model)

      form_tag(url, { :id => model.dom_id(:form) }.merge(options)) do
        puts generator.dom_id_field
        yield(generator)
      end
    end
  end

  def auto_complete_result(entries, base_id, field, index)
    return unless (entries)

    items = entries.collect do |entry|
        content_tag(:li, entry.send(field), :id => entry.dom_id("#{field}:auto_complete"))
    end

    content_tag(:ul, items.uniq)
  end

  # >> -- Custom Implementations --------------------------------------------

  def le_auto_complete_field(field_id, options = { })
    # README: http://wiki.script.aculo.us/scriptaculous/show/Ajax.Autocompleter
    # NOTE: Over-ride variable name here, preserve form ID
    function =  "var #{field_id.gsub(/:/, '_')} = new Ajax.Autocompleter("
    function << "'#{field_id}', "
    function << "'" + (options[:update] || "#{field_id}_auto_complete") + "', "
    function << "'#{url_for(options[:url])}'"

    js_options = { }
    js_options[:tokens] = array_or_string_for_javascript(options[:tokens]) if options[:tokens]
    js_options[:callback]   = "function(element, value) { return #{options[:with]} }" if options[:with]
    js_options[:indicator]  = "'#{options[:indicator]}'" if options[:indicator]
    js_options[:select]     = "'#{options[:select]}'" if options[:select]
    js_options[:paramName]  = "'#{options[:param_name]}'" if options[:param_name]
    js_options[:frequency]  = "#{options[:frequency]}" if options[:frequency]
    js_options[:method]     = "'#{options[:method].to_s}'" if options[:method]

    { :after_update_element => :afterUpdateElement, 
      :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
      js_options[v] = options[k] if options[k]
    end

    function << (', ' + options_for_javascript(js_options) + ')')

    javascript_tag(function)
  end
end
