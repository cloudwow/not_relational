module NotRelational

class IsNullTransform
  attr_accessor :name
  attr_accessor :source_column 
  def initialize(source_column )
    self.source_column =source_column 
    self.name = "#{name}_is_null".to_sym
  end
  def transform(value)
    value.nil?.to_s
  end
 
  
end
end
