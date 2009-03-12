module NotRelational

class TrackerDescription < PropertyDescription
    include SdbFormatter
 attr_accessor :name
  attr_accessor :other_class
  attr_accessor :refecting_attribute
  
    
  def initialize(name,other_class,refecting_attribute)
    self.name=name
  self.other_class=other_class
  self.refecting_attribute=refecting_attribute
   self.is_collection=true
    self.is_primary_key=false
  end
  
  def format_for_sdb(value)
    return value;
  end
  def parse_from_sdb( value)
    return value
  end
  
end
end