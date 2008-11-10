class FormToolkit::Generator::LiveEdit < FormToolkit::Generator::Basic
  def initialize(view, model, options = { })
    super(view, model, options)

    @form_url = (options[:url] or @view.url_for(@model.url_for(:update)))
    
    @form_options = {
      :id => @model.dom_id(:form)
    }.merge(options)
  end

protected
  def with_input_wrapper(&block)
    @view.content_tag(:form, :action => @form_url, :onsubmit => "return false", &block)
  end

  def text_options(method, options)
    super(
      method,
      {
        :onblur => onchange_js,
        :onkeyup => onkeyup_js,
        :onfocus => onfocus_js 
      }.merge(options)
    )
  end

  alias_method :password_options, :text_options
  alias_method :text_area_options, :text_options

  def select_html_options(method, options)
    super(
      method,
      {
        :onchange => onchange_js
      }.merge(options)
    )
  end

  def check_box_options(method, options)
    super(
      method,
      {
        :onchange => "this.value=this.checked;#{onchange_js}"
      }.merge(options)
    )
  end

  def auto_complete_options(method, options)
    super(
      method,
      {
        :onkeyup => onkeyup_js,
        :onfocus => onfocus_js,
        :onblur => [ sync_js(method), onchange_js(method) ] * ';'
      }.merge(options)
    )
  end

  def auto_complete_html_options(method, options)
    super(
      method,
      {
        :after_update_element => 'le_autocomplete_select',
        :url => @model.collection_url_for(method),
        :skip_style => true
      }.merge(options)
    )
  end

  # >> -- JavaScript Method Hooks -----------------------------------------

  def onfocus_js
    "le_onfocus(this)"
  end

  def onchange_js(method = nil)
    case (method)
    when nil:
      "le_onchange(this)"
    else
      "le_onchange(#{@model.element(method)}, this)"
    end
  end

  def onkeyup_js
    "le_restore(event, this)"
  end

  def sync_js(method = nil)
    "le_sync_target(this,#{@model.element(method)})"
  end
end
