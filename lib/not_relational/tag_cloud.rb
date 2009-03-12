# TagCloud.rb
# July 6, 2007
#

class TagCloud
  def calculate_max_min
       @max=nil
    @min=nil
       for key in @histogram.keys
      if @min==nil || @histogram[key]<@min
        @min=@histogram[key]
      end
      if @max==nil || @histogram[key]>@max
        @max=@histogram[key]
      end
    end
  end
  def initialize(tag_data)
   
    @histogram=tag_data.inject(Hash.new(0)){|hash,x| hash[x.tag_name]+=1;hash}
              
    @tag_data=tag_data.sort_by{|x|[@histogram[x.tag_name],x.tag_name]}
   calculate_max_min
    while @histogram.size>40
        @histogram.reject!{|key, value| value == @min }
        calculate_max_min
    end
    @normal_histogram={}
    if tag_data.length>0
      range=@max-@min
      for key in @histogram.keys
        if range==0
           @normal_histogram[key]=2
        else
           @normal_histogram[key]=((@histogram[key]-@min)*4)/range
        end
       
      end
      @tags=@histogram.keys
      @tags.sort!
    else 
      @tags=[]
    end
  end
  def tags
    return @tags
  end
  def get_count(tag_name)
    return @histogram[tag_name]
  end
   def get_magnitude(tag_name)
    return @normal_histogram[tag_name]
  end
end


