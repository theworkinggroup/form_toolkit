class Object
  # NOTE: Expressed as a method and not an alias since Object#to_s is
  #       not an accurate representation for all subclasses.
  def to_js
    to_s
  end
end

class String
  def to_js(style = ?')
    case (style)
    when ?",'"','""':
      inspect
    else
      # NOTE: \' has special meaning to gsub so replacement
      #       is expressed as a block, not a parameter.
      js = inspect.gsub(/\'/) { '\\\'' }
      
      js[0] = ?'
      js[-1] = ?'
      
      js
    end
  end
end

class NilClass
  def to_js
    'null'
  end
end

class Array
  def to_js(style = ?[)
    case (style)
    when '(',?(,'()',:list:
      '(' + collect(&:to_js) * ',' + ')'
    when nil,false,:none,'':
      collect(&:to_js) * ','
    else
      '[' + collect(&:to_js) * ',' + ']'
    end
  end
end

class Hash
  def to_js
    '{' + collect { |k,v| "#{k}:#{v.to_js}" } * ',' + '}'
  end
end
