
class Mediaitem < NotRelational::DomainModel

  include NotRelational::Locatable
  property :id,:string,:is_primary_key=>true
  property :guid,:string,:unique=>true
  property :group_id , :string
  property :title , :string
  property :user_login , :string
  property :description , :text  
  property :latitude        ,         :float                                                                                                                 
  property :longitude       ,         :float                                                                                                                 
                                                                                                        
  property :address , :string
  property :bucket , :string
  property :length_in_seconds , :unsigned_integer
  property :HasVideo , :boolean
  property :HasAudio , :boolean
  property :HasImage , :boolean
  property :is_private , :boolean
  property :created_time ,:date  
  property :metadata, :string ,:is_collection=>true

  has_many :Mediafile,nil,nil,:dependent=>:destroy
  has_many :Tag,nil,nil,:dependent=>:destroy
  has_many :Comment,nil,nil,:dependent=>:destroy
  has_many :Rating,nil,nil,:dependent=>:destroy
  has_many :AlbumMediaItem,nil,nil,:dependent=>:destroy
  
  index :hasimage_and_is_private,[:HasImage,:is_private]
  index :hasvideo_and_is_private,[:HasVideo,:is_private]
  index :hasaudio_and_is_private,[:HasAudio,:is_private]
  index :hasaudio_hasvideo_and_is_private,[:HasAudio,:HasVideo,:is_private]
  
  many_to_many :Album,:AlbumMediaItem,:mediaitem_id,:album_id,:albums
  belongs_to :Group
  def Mediaitem.recent(how_many=24)
    Mediaitem.find(:all,:order_by => :created_time,:order => :descending,:limit => how_many)
      
   
  end
  def Mediaitem.recent_video(how_many=24)
            
    Mediaitem.find_by_hasvideo_and_is_private(
      true,
      false ,
      :order_by => :created_time,
      :order => :descending,
      :limit => how_many)
   
  end
  def Mediaitem.recent_audio(how_many=24)
    Mediaitem.find_by_hasaudio_and_is_private(
      true,
      false ,
      :order_by => :created_time,
      :order => :descending,
      :limit => how_many)
   
  end
  #hasimage is unreliable in the db
  def HasImage
    return false if self.HasVideo
    return false if self.HasAudio
    return true
  end
  def Mediaitem.recent_images(how_many=24)
    #images are those that aren't video or audio
    #hasimage flag is not rustworthy
    Mediaitem.find_by_hasaudio_hasvideo_and_is_private(false,false,false ,:order_by => :created_time,:order => :descending,:limit => how_many)
  end
  def create_group_url(group_name)
    return "#{Group.url_from_name(group_name)}/media/#{guid}"
  end
  def relative_url_from_root
    return "media/"+self.guid+"/show.html"
  end
  def url
    return "/media/"+self.guid+"/show.html"
  end
  def post_comment_url
    return "/procyon/post_media_comment_form?mediaitem_id=#{id.to_s}&mediaitem_guid=#{guid}&return_url=#{CGI.escape relative_url_from_root}&mediaitem_thumb_w=#{thumbfile.width}&mediaitem_thumb_h=#{thumbfile.height}&mediaitem_thumb_url=#{thumbfile.url}"
  end
  def thumbfile
    for mediafile in self.mediafiles 
      if mediafile.width<=120 and mediafile.height<=120 and (mediafile.width==120 or mediafile.height==120) and mediafile.mimeType.index('image/')==0
        return mediafile
      end
    end
    return tiny_thumbfile
  end
  def tiny_thumbfile
    for mediafile in self.mediafiles 
      #not square
      if mediafile.width<=60  and mediafile.height<=60  and (mediafile.height==60 || mediafile.width==60) and mediafile.mimeType.index('image/')==0
        return mediafile
      end
    end
    return nil
  end
  def square_thumbfile
    for mediafile in self.mediafiles 
      if mediafile.width==100  and mediafile.height==100  and mediafile.mimeType.index('image/')==0
        return mediafile
      end
    end
    return tiny_thumbfile
  end
  def tiny_square_thumbfile
    for mediafile in self.mediafiles 
      if mediafile.width==50  and mediafile.height==50  and mediafile.mimeType.index('image/')==0
        return mediafile
      end
    end
    return tiny_thumbfile
  end
  def big_thumbfile
    for mediafile in self.mediafiles 
      if mediafile.width>120 and mediafile.width<=240 and mediafile.height>120 and mediafile.height<=240 and mediafile.mimeType.index('image/')==0
        return mediafile
      end
    end
    return thumbfile
  end
  def file640
    biggest=nil
    for mediafile in self.mediafiles 
      if mediafile.width<=640 and  mediafile.height<=640 and mediafile.width>1
        if !biggest || mediafile.width>biggest.width
          biggest=mediafile
        end
      end
    end
    if !biggest
      return big_thumbfile
    end
    return biggest
  end
  def fileMaxSize
    result=nil
    for mediafile in self.mediafiles 
      if result==nil || mediafile.width>result.width 
        result=mediafile
      end
    end
     
    return result
  end
  def large_files
    result=[]
    for mediafile in self.mediafiles 
      if mediafile.width>240 or  mediafile.height>240 
        result<<mediafile
      end
    end
    if result.length==0
      result<<big_thumbfile
    end
    return result
  end
  def get_file_by_size_string(size)
    the_mediafile=nil
    for mediafile in self.mediafiles
      if "#{mediafile.width}x#{mediafile.height}"==size
        the_mediafile=mediafile
      end
    end
    return the_mediafile
  end
  def get_tag_cloud
    tag_data=self.tags
    histogram=tag_data.inject(Hash.new(0)){|hash,x| hash[x.tag_name]+=1;hash}
    tag_data=histogram.keys       
    tag_data=tag_data.sort_by{|x|-histogram[x]}
  end
      
  def kill
    #      for media_file in mediafiles
    #        media_file.destroy
    #      end
    #      for album_item in albummediaitems
    #        album_item.destroy
    #      end
    self.destroy
  end
  def add_rating(rating)
    rating.media_item.id=self.id
    rating.save
  end

  # Helper method that returns the average rating
  #
  def rating
    average = 0.0
    ratings.each { |r|
      average = average + r.rating
    }
    if ratings.size != 0
      average = average / ratings.size
    end
    average
  end

  # Check to see if a user already rated this rateable
  def rated_by_user?(user_name)
    rtn = false
    if user_name
      self.ratings.each { |b|
        rtn = true if user_name == b.user_name
      }
    end
    rtn
  end
  def get_rating_by_user_name(user_name)
    rtn = 0
    if user_name
      self.ratings.each { |b|
        rtn = b.rating if user_name == b.user_name
      }
    end
    rtn
  end
  def add_media_comment(user_name,comment)
    newComment=Comment.new
    newComment.mediaitem_id=self.id
    newComment.content=comment
    newComment.user_name=user_name
    newComment.posted_time=Time.new.gmtime
    newComment.save
  end
  def Mediaitem.add_media_comment(user_name,mediaitem_id,title,comment)

    mediaitem=Mediaitem.find(mediaitem_id)
    if mediaitem
  
      mediaitem.add_media_comment(user_name,comment)


    end
  end

  def Mediaitem.convert_arg_to_mediaitem(mediaitem_arg)
    item=nil
    if mediaitem_arg.respond_to?(:HasImage)
      item=mediaitem_arg
    else
      item=Mediaitem.find_by_guid(mediaitem_arg)
    end
    return item
  end
end
