module NotRelational

  #used in queries to limit the results to a certain range
  # Example:
  #     MyDomainClass.find(:all,:order_by=>"tag_name",
  #                :params =>{
  #                    :group_with_media=>AttributeRange.new(:greater_than_or_equal_to=>calculate_group_with_media(group_id,"")}   )
  class AttributeRange
    attr_accessor :less_than
    attr_accessor :greater_than
    attr_accessor :less_than_or_equal_to
    attr_accessor :greater_than_or_equal_to
    attr_accessor :attribute_description #if this exists we act on objects else we act on attributes
    
    def initialize(options)
      
      self.attribute_description=options[:attribute_description]
      
      self.less_than=options[:less_than]
      self.greater_than=options[:greater_than]
      self.less_than_or_equal_to=options[:less_than_or_equal_to]
      self.greater_than_or_equal_to=options[:greater_than_or_equal_to]
      
    end
    def matches?(arg)
      value=arg
      if self.attribute_description
        #its an object so pull out the value
        value=arg[attribute_description.name]
      end
      return false if value==nil
      return false if self.less_than                && (value <=> self.less_than)               >-1
      return false if self.less_than_or_equal_to    && (value <=> self.less_than_or_equal_to)   ==1
      return false if self.greater_than             && (value<=>self.greater_than)              <1
      return false if self.greater_than_or_equal_to &&(value<=>self.greater_than_or_equal_to)   ==-1
      
      return true
    end
    def to_sdb_query
      query=''
      if self.less_than 
        query << "  `#{attribute_description.name}` < '#{ attribute_description.format_for_sdb( self.less_than)}'"
      end
      if self.greater_than  
        query << ' and ' if query.length>0
        query << "  `#{attribute_description.name}` > '#{ attribute_description.format_for_sdb( self.greater_than)}'"
      end
      if  self.less_than_or_equal_to 
        query << ' and ' if query.length>0
        query << "  `#{attribute_description.name}` <= '#{ attribute_description.format_for_sdb( self.less_than_or_equal_to)}'"
      end
      if  self.greater_than_or_equal_to 
        query << ' and ' if query.length>0
        query << "  `#{attribute_description.name}` >= '#{ attribute_description.format_for_sdb( self.greater_than_or_equal_to)}'"
      end
      
      return  query
    end

    def attribute_name_to_s
      if attribute_description
        attribute_description.name
      else
        ""
      end
    end
    def to_s
      query=''
      if self.less_than 
        query << " #{attribute_name_to_s} < '#{ self.less_than}'"
      end
      if self.greater_than  
        query << ' and ' if query.length>0
        query << "  #{attribute_name_to_s} > '#{ self.greater_than}'"
      end
      if  self.less_than_or_equal_to 
        query << ' and ' if query.length>0
        query << "  #{attribute_name_to_s} <= '#{ self.less_than_or_equal_to}'"
      end
      if  self.greater_than_or_equal_to 
        query << ' and ' if query.length>0
        query << "  #{attribute_name_to_s} >= '#{ self.greater_than_or_equal_to}'"
      end
      
      return  query

    end
  end
  
end
