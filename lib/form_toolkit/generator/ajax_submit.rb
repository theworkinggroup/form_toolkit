class FormToolkit::Generator::AjaxSubmit < FormToolkit::Generator::Basic
protected
  def submit_options(options)
    {
      :id => model_dom_id(:submit),
      :onclick => 'ft_formsubmit(this)'
    }.merge(options)
  end
end
