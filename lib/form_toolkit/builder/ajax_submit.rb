class FormToolkit::Builder::AjaxSubmit < FormToolkit::Generator::Basic
protected
  # DEPRECATED: Can be created using jQuery selectors
  
  def submit_options(options)
    {
      :id => model_dom_id(:submit),
      :onclick => 'ft_formsubmit(this)'
    }.merge(options)
  end
end
