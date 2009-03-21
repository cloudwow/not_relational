module NotRelational


class MemoryStorage
  
  def initialize
    clear
  end
  def get(bucket,key)
    return @stuff[bucket+"sdsdw555"+key]
        
  end
  def delete(bucket,key)
    @attributes.delete(bucket+"sdsdw555"+key)
    return @stuff.delete(bucket+"sdsdw555"+key)
        
  end
  def put(bucket,key,object,attributes=nil)
    @stuff[bucket+"sdsdw555"+key]=object
    @attributes[bucket+"sdsdw555"+key]=attributes if attributes    
  end
  def get_content_type(bucket,key)
    return @attributes[bucket+"sdsdw555"+key]['Content-Type'] if @attributes.has_key?(bucket+"sdsdw555"+key)
    return nil
  end
def copy(from_bucket,from_key,to_bucket,to_key,attributes=nil)
  o=get(from_bucket,from_key)
  put(to_bucket,to_key,o,attributes)

end
  def clear()
    @stuff={}
    @attributes={}
  end
  def real_s3
    return self
  end
end

end