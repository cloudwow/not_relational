module NotRelational
 

class EqualsCondition
    attr_accessor :attribute_description
  attr_accessor :value
  def initialize(attribute_description,value)
    self.attribute_description=attribute_description
    self.value=value
  end
   def matches?(domain_model)
       return domain_model[attribute_description.name]==value
   end
   def to_sdb_query
     return "'#{self.attribute_description.name}'='#{self.attribute_description.format_for_sdb(self.value)}'"
   end
end
end