module NotRelational
 

class StartsWithCondition
    attr_accessor :attribute_description
  attr_accessor :value
  def initialize(attribute_description,value)
    self.attribute_description=attribute_description
    self.value=value
  end
   def matches?(domain_model)
     if domain_model[attribute_description.name]==nil
       return value==nil || value==:NULL
     end
       return domain_model[attribute_description.name].index(value)==0
   end
   def to_sdb_query
     return "'#{self.attribute_description.name}' starts-with '#{self.attribute_description.format_for_sdb(self.value)}'"
   end
   def to_s
     "#{self.attribute_description.name} starts with #{value}"
   end
end
end
