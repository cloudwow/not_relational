module NotRelational


class LocalStorage
  
  def initialize
  end
  def get(bucket,key)
    raise "not impl"
        
  end
  def delete(bucket,key)

    raise "not impl"
  end
  def put(bucket,key,object,attributes=nil)

    raise "not impl"
  end
  def get_content_type(bucket,key)

    raise "not impl"
  end
  def create_direct_url(bucket,key,time_to_live_minutes=60)
      return "#{@root_dir}/#{bucket}/#{key}"

  end

  def get_content_type(bucket,key)
    return "audio/mpeg"

  end
  def copy(old_bucket,old_key,new_bucket,new_key,options)
    raise "not impl"
  end
end

end