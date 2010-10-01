module NotRelational
  

  class OrCondition
    attr_accessor :child_conditions
    
    def initialize(child_conditions=[])
      self.child_conditions=child_conditions
    end
    
    def add(child_condition)
      self.child_conditions << child_condition
    end
    
    def matches?(domain_model)
      
      self.child_conditions.each do | condition|
        if condition.respond_to?(:matches?)
          if condition.matches?(domain_model)
            return true
          end
          
        end
      end
      return false
    end
    def to_sdb_query
      first =true
      query=""
      count=0
      self.child_conditions.each do | condition|
        count=count+1
        if ! first
          # if count>4
          #   query<< ")  union  ("
          #   count=0
          # else
            query<< " or "
          #end
        end
        first=false
        
        if condition.respond_to?(:to_sdb_query)
          
          query << condition.to_sdb_query
        else  
          query << condition.to_s      
        end
      end
      return query
    end
  end
end
