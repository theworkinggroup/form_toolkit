class FormToolkit::Builder < ActionView::Helpers::FormBuilder
  # == Accessors ============================================================
  
  cattr_accessor :default_options
  cattr_accessor :options_for_type

  attr_accessor :name
  attr_accessor :label
  attr_accessor :element
  attr_accessor :type
  
  attr_accessor :target
  attr_accessor :prefix
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================
  
  def initialize(object_name, object, template, options, proc)
    if (default_options)
      options = options.merge(default_options)
    end
    
    @partial = options.delete(:partial)
    
    super(object_name, object, template, options, proc)
  end
  
  def capture_block(*args, &block)
    @template.capture(*args, &block)
  end
  
  def as_js(&block)
    @template.puts(@template.javascript_tag(capture_block(&block)))
  end

  def type_for(method)
    @object.type_for(method)
  end

  def field_type(method)
    @object.field_type(method)
  end
  
  def with_field(method, options = { }, &block)
    generator = generator_for_field(method, options)
    
    return genereator unless (block_given?)

    @template.capture(generator, &block)
  end
  
  def generator_for_association(association)
    placeholder = placeholder_for_association(association)
    placeholder.id = '__ID__'
    
    generator = self.class.new(
      @template,
      @object,
      :target => placeholder,
      # FIX: __ID__ => dom_id instance number
      :prefix => [ association, '__ID__' ]
    )
  end

  def has_many(association, options = { }, &block)
    association = association.to_sym
    generator = generator_for_association(association)

    @object.send(association).each do |model|
      generator.target = model
      generator.prefix = prefix_for([ association, model.id ])
      
      if (options[:partial])
        @template.render(:partial => options[:partial], :object => generator)
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
  
  def fieldset(label, options = { }, &block)
    @template.content_tag(:fieldset) do
      [
        @template.content_tag(:legend, label),
        @template.capture(&block)
      ]
    end
  end
  
  def link_to_add(association, link_text = nil, &block)
    link_text = "Add #{association.to_s.titleize}" if (link_text.blank?)
    association = association.to_sym
    generator = generator_for_association(association)

    [
      @template.javascript_tag(
        @template.capture(generator, &block)
      ), 
      @template.link_to_function(link_text, '#')
    ]
  end
  
  def errors(method, options = { }, &block)
    only = options.delete(:only)
    
    errors = @object.errors.on(method)

    options = {
      :id => @object.dom_id([ method, :errors ])
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
          
          @template.capture(errors, &block) if (block_given?)
          
          errors
        else
          error_msg = errors.is_a?(String) ? [ errors ] : errors
          
          errors.collect! { |error| @template.capture(error, &block) } if (block_given?)
          
          errors
        end
    end
    
    # FUTURE: Add errors_on support here, empty for now
    @template.content_tag(:div, error_msg, options)
  end
  
  # -- Input Fields ---------------------------------------------------------
  
  def label_for(method, verbiage = nil, options = { }, &block)
    options = {
      :id => @object.dom_id([ method, :label ]),
      :for => @object.dom_id(method)
    }.merge(options)
    
    block_given? ?
      @template.content_tag(:label, options, &block) :
      @template.content_tag(:label, verbiage || method.to_s.titleize, options)
  end

  def field(method, options = { })
    field_type = (options.delete(:type) or @object.field_type(method))
    
    send(:"#{field_type}_field", method, options)
  end

  def return_field
    @template.hidden_field_tag(
      :r,
      @template.url_for(@template.return_url)
    )
  end

  def dom_id_field
    @template.hidden_field_tag(
      model_input_name(:dom_id),
      model_dom_id
    )
  end

  def check_box_field(method, options = { })
    options = prepare_options_for(:check_box, options)
    
    with_partial_wrapper(method, options) do
      with_input_wrapper do
        [
          @template.check_box_tag(
            model_input_name(method),
            1,
            resolve_method_to_value(method),
            check_box_options(method, options)
          ),
          @template.hidden_field_tag(
            model_input_name(method),
            0
          )
        ]
      end
    end
  end
  alias_method :check_box, :check_box_field

  def file_field(method, options = { })
    options = prepare_options_for(:file, options)
    
    with_partial_wrapper(method, options) do
      with_input_wrapper do
        @template.file_field_tag(
          model_input_name(method)
        )
      end
    end
  end

  def hidden_field(method)
    @template.hidden_field_tag(
      model_input_name(method),
      resolve_method_to_value(method)
    )
  end

  def password_field(method, options = { })
    options = prepare_options_for(:password, options)

    with_partial_wrapper(method, options) do
      with_input_wrapper do
        @template.password_field_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          password_options(method, options)
        )
      end
    end
  end

  def select_field(method, items, options = { }, html_options = { })
    options = prepare_options_for(:select, options)
    
    with_partial_wrapper(method, options) do
      with_input_wrapper do
        @template.select_tag(
          model_input_name(method),
          @template.options_for_select(
            items,
            resolve_method_to_value(method)
          ),
          select_html_options(method, html_options)
        )
      end
    end
  end
  alias_method :select, :select_field

  def submit(label = nil, options = { }, &block)
    @template.content_tag(:div, :class => 'submit_type form_element') do
      [
        @template.submit_tag(
          label,
          submit_options(options)
        ),
        block_given? ? capture_block(&block) : nil
      ]
    end
  end
  
  def integer_field(method, options = { })
    text_field(method, options.merge(:class => 'integer'))
  end

  def text_field(method, options = { })
    options = prepare_options_for(:text, options)
    
    with_partial_wrapper(method, options) do
      with_input_wrapper do
        @template.text_field_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          text_options(method, options)
        )
      end
    end
  end

  def text_area_field(method, options = { })
    options = prepare_options_for(:text_area, options)
    
    with_partial_wrapper(method, options) do
      with_input_wrapper do
        @template.text_area_tag(
          model_input_name(method),
          resolve_method_to_value(method),
          text_area_options(method, options)
        )
      end
    end
  end
  alias_method :text_area, :text_area_field
  
  # -- Basic Extensions -----------------------------------------------------

  def static_field(method)
    @method = method
    @name = model_input_name(@method)
    @label = options.delete([:label]) || @object.label_for(@method)
    @element = @object.send(method)
    
    @partial ? @template.render(:partial => @partial, :object => self) : @element
  end
  
  def delete_item_link(label, options = { })
    @template.link_to_remote(
      label,
      delete_item_options(options)
    )
  end

  def auto_complete_field(value_method, display_method, options = { }, completion_options = { })
    @type = :text

    method_auto_complete = "#{value_method}_auto_complete".to_sym
    method_select = "#{value_method}_select".to_sym

    with_partial_wrapper(method, options) do
      with_input_wrapper do
        [
          @template.hidden_field_tag(
            model_input_name(value_method),
            resolve_method_to_value(value_method),
            :id => model_dom_id(value_method) 
          ),
          @template.text_field_tag(
            model_input_name(method_auto_complete),
            resolve_method_to_value(display_method),
            auto_complete_options(value_method, options).merge(:id => model_dom_id(method_auto_complete))
          ),
          @template.content_tag(
            :div,
            "",
            :id => model_dom_id(method_select),
            :class => "auto_complete"
          ),
          @template.le_auto_complete_field(
            model_dom_id(method_auto_complete),
            {
              :after_update_element => "le_autocomplete_select",
              :update => model_dom_id(method_select),
              :url => @object.url_for(method_auto_complete),
              :skip_style => true
            }.merge(completion_options)
          )
        ]
      end
    end
  end
  
  def label?
    !(@label === false)
  end

  def required?
    @object.class.required_field?(@method)
  end

  def errors?
    @object.errors.invalid?(@method)
  end
  
  def errors(full_messages = true)
    messages = @object.errors.on(@method)
    
    return messages unless (full_messages)
    
    using_label = @options[:label] || @object.label_for(@method)
  
    case (messages)
    when String:
      "#{using_label} #{messages}"
    when Array:
      messages.collect do |message|
        "#{using_label} #{message}"
      end
    end
  end

  def progress(&block)
    @template.tag(:div, :style => 'display:none', :class => 'form_progress', &block)
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
    reflection = @object.class.reflect_on_association(method)

    reflection and reflection.klass
  end
  
  def placeholder_for_association(method)
    association_class = reflection_model_for_field(method)
    
    association_class and association_class.new
  end
  
  def target_for_field(method)
    @object.send(method) or
      reflection_model_for_field(method)
  end

  def generator_for_field(method, options)
    method = method.to_sym
    
    self.class.new(
      @template,
      @object,
      options.merge(
        :prefix => prefix_for(method),
        :target => target_for_field(method)
      )
    )
  end
  
  def model_input_name(method)
    @object.input_name(prefix_for(method))
  end

  def model_dom_id(method = nil)
    @object.dom_id(prefix_for(method))
  end

  def with_input_wrapper(&block)
    yield
  end

  def with_partial_wrapper(method, options = { }, &block)
    @method = method
    @name = model_input_name(@method)
    @element = yield
    @label = options.delete(:label)
    @label = @object.label_for(@method) if (@label.nil?)
    
    _partial = options.delete(:partial)
    _partial = @partial if (_partial.nil?)
    
    _partial ? @template.render(:partial => _partial, :object => self) : @template.render(:text => @element)
  end
  
  def prepare_options_for(type, options)
    @type = type
    
    combined_options = (default_options or { })
    combined_options = combined_options.merge(@options[type]) if (@options[type])
    combined_options.merge(options)
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
      :url => @object.collection_url_for(method),
      :skip_style => true
    }.merge(options)
  end

  def delete_item_options(options)
    {
      :url => @object.url_for,
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
      @object.respond_to?(method) ? @object.send(method) : nil
    when Array:
      target = @object
      
      method.each do |call|
        case (target)
        when Array, Hash:
          target = target[call]
        when true, false, nil:
          return target
        else
          target = target.respond_to?(call) ? target.send(call) : nil
        end
      end
      
      target
    end
  end
end
