module NotRelational


class MemoryStorage

  attr_reader :read_count
  attr_reader :write_count
  def initialize
    clear
  end
  def clear_counts
    @read_count=0
    @write_count=0
  end
  def real_s3_get(bucket,key)
    get(bucket,key)
  end
  def real_s3_put(bucket,key,object,attributes=nil)
    put(bucket,key,object,attributes)

  end

  def get(bucket,key)
    @read_count+=1
    return @stuff[bucket+"sdsdw555"+key]
        
  end
  def delete(bucket,key)
        @write_count+=1

    @attributes.delete(bucket+"sdsdw555"+key)
    return @stuff.delete(bucket+"sdsdw555"+key)
        
  end
  def put(bucket,key,object,attributes=nil)
        @write_count+=1

    @stuff[bucket+"sdsdw555"+key]=object
    @attributes[bucket+"sdsdw555"+key]=attributes if attributes    
  end
  def get_content_type(bucket,key)
        @read_count+=1

    return @attributes[bucket+"sdsdw555"+key]['Content-Type'] if @attributes.has_key?(bucket+"sdsdw555"+key)
    return nil
  end
def copy(from_bucket,from_key,to_bucket,to_key,attributes=nil)
      @write_count+=1

  o=get(from_bucket,from_key)
  put(to_bucket,to_key,o,attributes)

end
  def clear()
    @stuff={}
    @attributes={}
    clear_counts
  end
  def real_s3
    return self
  end
end

end
