
module NotRelational

 

class LazyLoadingText
  attr_reader :is_dirty
   attr_reader :has_loaded
  def initialize(get_clob_proc)
    @get_clob_proc=get_clob_proc
    @has_loaded=false
    @is_dirty=false
  end
  
  def value=(v)
    @is_dirty=true
    @has_loaded=true
    @value=v
  end
  def value
    if !@did_load
        @value= @get_clob_proc.call      
        @has_loaded=true          
    end
    return @value
    
  end
end
end