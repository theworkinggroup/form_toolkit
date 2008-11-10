module FormToolkit
  module Js
  end
end

class FormToolkit::Js::Scalar
  def initialize(name)
    @value = name
  end
  
  def new(*args)
    self.class.new(*args)
  end
  
  def inspect
    @value and @value.inspect
  end
  
  def to_s
    @value
  end
  
  def to_json
    @value and @value.to_json or 'null'
  end
  
  def to_js(style = nil)
    @value
  end
  
  def +(value)
    new(@value + value)
  end
  
  def <<(value)
    @value << value
  end
  
  def [](*indexes)
    new(to_js + indexes.to_js)
  end
  
  def to_js_call(name, *args)
    new(to_js + '.' + name.to_s + ((js_property?(name) and args.empty?) ? '' : args.to_js(:list)))
  end
  
  def ==(value)
    @value == value
  end

  def ===(value)
    @value === value
  end
  
protected
  def js_property?(name)
    false
  end

  def method_missing(name, *args)
    to_js_call(name, *args)
  end
end
