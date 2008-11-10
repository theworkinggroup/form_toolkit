class FormToolkit::Generator::Basic
  attr_accessor :target
  attr_accessor :prefix
  
  def initialize(view, model, options = { })
    @view = view
    @model = model
    @target = (options[:target] or @model)
    @options = options
    @partial = options[:partial]
    @prefix = options[:prefix]
  end
  
  def capture_block(*args, &block)
    @view.capture(*args, &block)
  end
  
  def as_js(&block)
    @view.puts(@view.javascript_tag(capture_block(&block)))
  end

  def type_for(method)
    @target.type_for(method)
  end

  def field_type(method)
    @target.field_type(method)
  end
  
  def with_field(method, options = { }, &block)
    generator = generator_for_field(method, options)
    
    return genereator unless (block_given?)

    @view.capture(generator, &block)
  end
  
  def generator_for_association(association)
    placeholder = placeholder_for_association(association)
    placeholder.id = '__ID__'
    
    generator = self.class.new(
      @view,
      @model,
      :target => placeholder,
      # FIX: __ID__ => dom_id instance number
      :prefix => [ association, '__ID__' ]
    )
  end

  def has_many(association, options = { }, &block)
    association = association.to_sym
    generator = generator_for_association(association)

    @target.send(association).each do |model|
      generator.target = model
      generator.prefix = prefix_for([ association, model.id ])
      
      if (options[:partial])
        @view.render(:partial => options[:partial], :object => generator)
      else
        yield(generator)
      end
    end
  end
  
  def with_partial(name, &block)
    if (block_given?)
      partial = @partial
      @partial = name
      yield(block) if (block_given?)
      @partial = partial
    else
      @partial = name
    end
  end
  
  def link_to_add(association, link_text = nil, &block)
    link_text = "Add #{association.to_s.titleize}" if (link_text.blank?)
    association = association.to_sym
    generator = generator_for_association(association)

    [
      @view.javascript_tag(
        @view.capture(generator, &block)
      ), 
      @view.link_to_function(link_text, '#')
    ]
  end
  
  def errors(method, options = { }, &block)
    only = options.delete(:only)
    
    errors = @target.errors.on(method)

    options = {
      :id => @target.dom_id([ method, :errors ])
    }.merge(options)
    
    options[:style] ||= ''
    options[:style] << ';' unless (options[:style].blank?)
    options[:style] << 'display:none' if (errors.blank?)
    
    error_msg = ''
    
    if (errors)
      error_msg = 
        case (only)
        when :first:
          errors = errors.is_a?(String) ? errors : errors.first
          
          @view.capture(errors, &block) if (block_given?)
          
          errors
        else
          error_msg = errors.is_a?(String) ? [ errors ] : errors
          
          errors.collect! { |error| @view.capture(error, &block) } if (block_given?)
          
          errors
        end
    end
    
    # FUTURE: Add errors_on support here, empty for now
    @view.content_tag(:div, error_msg, options)
  end
  
  # -- Input Fields ---------------------------------------------------------
  
  def label(method, verbiage = nil, options = { }, &block)
    options = {
      :id => @target.dom_id([ method, :label ]),
      :for => @target.dom_id(method)
    }.merge(options)
    
    block_given? ?
      @view.content_tag(:label, options, &block) :
      @view.content_tag(:label, verbiage || method.to_s.titleize, options)
  end
  
  def field(method, options = { })
    field_type = (options.delete(:type) or @target.field_type(method))
    
    call = "#{field_type}_field".to_sym
    
    send(call, method, options)
  end

  def hidden_field(method)
    @view.hidden_field_tag(
      model_input_name(method),
      resolve_method_to_value(method)
    )
  end

  def dom_id_field
    @view.hidden_field_tag(
      model_input_name(:dom_id),
      model_dom_id
    )
  end
  
  def text_field(method, options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        @view.text_field_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          text_options(method, options)
        )
      end
    end
  end

  def password_field(method, options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        @view.password_field_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          password_options(method, options)
        )
      end
    end
  end

  def text_area_field(method, options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        @view.text_area_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          text_area_options(method, options)
        )
      end
    end
  end

  def select_field(method, items, options = { }, html_options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        @view.select_tag(
          model_input_name(method),
          @view.options_for_select(
            items,
            resolve_method_to_value(method)
          ),
          select_html_options(method, html_options)
        )
      end
    end
  end

  def check_box_field(method, options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        [
          @view.check_box_tag(
            model_input_name(method),
            1,
            resolve_method_to_value(method),
            check_box_options(method, options)
          ),
          @view.hidden_field_tag(
            model_input_name(method),
            0
          )
        ]
      end
    end
  end

  def file_field(method, options = { })
    with_partial_wrapper(method) do
      with_input_wrapper do
        @view.file_field_tag(
          model_input_name(method)
        )
      end
    end
  end

  def delete_item_link(label, options = { })
    @view.link_to_remote(
      label,
      delete_item_options(options)
    )
  end

  def auto_complete_field(value_method, display_method, options = { }, completion_options = { })
    method_auto_complete = "#{value_method}_auto_complete".to_sym
    method_select = "#{value_method}_select".to_sym

    with_partial_wrapper(method) do
      with_input_wrapper do
        [
          @view.hidden_field_tag(
            model_input_name(value_method),
            resolve_method_to_value(value_method),
            :id => model_dom_id(value_method) 
          ),
          @view.text_field_tag(
            model_input_name(method_auto_complete),
            resolve_method_to_value(display_method),
            auto_complete_options(value_method, options).merge(:id => model_dom_id(method_auto_complete))
          ),
          @view.content_tag(
            :div,
            "",
            :id => model_dom_id(method_select),
            :class => "auto_complete"
          ),
          @view.le_auto_complete_field(
            model_dom_id(method_auto_complete),
            {
              :after_update_element => "le_autocomplete_select",
              :update => model_dom_id(method_select),
              :url => @model.url_for(method_auto_complete),
              :skip_style => true
            }.merge(completion_options)
          )
        ]
      end
    end
  end
  
  def submit(label = nil, options = { })
    @view.submit_tag(
      label,
      submit_options(options)
    )
  end

protected
  def prefix_for(method)
    case (method)
    when Array:
      @prefix ? @prefix + method : method
    else
      @prefix ? @prefix + [ method ] : [ method ]
    end
  end
  
  def reflection_model_for_field(method)
    reflection = @target.class.reflect_on_association(method)

    reflection and reflection.klass
  end
  
  def placeholder_for_association(method)
    association_class = reflection_model_for_field(method)
    
    association_class and association_class.new
  end
  
  def target_for_field(method)
    @target.send(method) or
      reflection_model_for_field(method)
  end

  def generator_for_field(method, options)
    method = method.to_sym
    
    self.class.new(
      @view,
      @model,
      options.merge(
        :prefix => prefix_for(method),
        :target => target_for_field(method)
      )
    )
  end
  
  def model_input_name(method)
    @model.input_name(prefix_for(method))
  end

  def model_dom_id(method = nil)
    @model.dom_id(prefix_for(method))
  end

  def with_input_wrapper(&block)
    yield
  end
  
  def with_partial_wrapper(label, &block)
    @partial ? @view.render(:partial => @partial, :object => label, &block) : yield
  end

  def text_options(method, options)
    {
      :id => model_dom_id(method),
      :class => 'text'
    }.merge(options)
  end

  def password_options(method, options)
    {
      :id => model_dom_id(method),
      :class => 'password'
    }.merge(options)
  end

  def text_area_options(method, options)
    {
      :id => model_dom_id(method),
      :class => 'textarea'
    }.merge(options)
  end

  def check_box_options(method, options)
    {
      :id => model_dom_id(method),
      :class => 'checkbox'
    }.merge(options)
  end

  def standard_options(method, options)
    {
      :id => model_dom_id(method),
    }.merge(options)
  end

  [ :select_html ].each do |element_type|
    alias_method "#{element_type}_options".to_sym, :standard_options
  end

  def select_options(method, options)
    options
  end

  def auto_complete_options(method, options)
    {
      :class => 'text',
      :size => 25
    }.merge(options)
  end

  def auto_complete_html_options(method, options)
    {
      :url => @model.collection_url_for(method),
      :skip_style => true
    }.merge(options)
  end

  def delete_item_options(options)
    {
      :url => @model.url_for,
      :method => :delete,
      :confirm => "Are you sure you want to delete this record? This action cannot be reversed."
    }.merge(options)
  end
  
  def submit_options(options)
    {
      :id => model_dom_id(:submit)
    }.merge(options)
  end
  
  def resolve_method_to_value(method)
    case (method)
    when Symbol, String:
      @target.respond_to?(method) ? @target.send(method) : nil
    when Array:
      target = @target
      
      method.each do |call|
        case (target)
        when Array, Hash:
          target = target[call]
        when true, false, nil:
          return result
        else
          target = target.respond_to?(call) ? target.send(call) : nil
        end
      end
      
      target
    end
  end
end
