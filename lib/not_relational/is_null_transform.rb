module NotRelational

  # use this in an index to convert a column value into Null/NotNull boolean
  # example:
  # index :group_with_media ,[:group_id,NotRelational::IsNullTransform.new(:mediaitem_id)]
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
