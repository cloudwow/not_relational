require 'digest/sha1'
require "uri"

require 'not_relational/geo.rb'
require 'not_relational/tag_cloud.rb'
require 'place.rb'
require 'or_condition.rb'
require 'domain_model.rb'

class Node < NotRelational::DomainModel
  extend NotRelational::Geo::Locatable
  include NotRelational::Geo::Locatable
  encrypt_me
  property :id,:string,:is_primary_key=>true
  property :creator         ,         :unsigned_integer                                                                                                               
  property :creationTime    ,         :date             ,:is_encrypted=>false
  property :publicRead      ,         :boolean                                                                                                            
  property :publicWrite     ,         :boolean                                                                                                            
  property :isChannel       ,         :boolean                                                                                                         
  property :isComment       ,         :boolean                                                                                                            
  property :isLink          ,         :boolean                                                                                                            
  property :clicks          ,         :unsigned_integer ,:is_encrypted=>false
  property :isTrash         ,         :boolean                                                                                                            
  property :isVersion       ,         :boolean                                                                                                            
  property :isVersioned     ,         :boolean                                                                                                            
  property  :isDataFeed      ,         :boolean                                                                                                            
  property :isRss           ,         :boolean                                                                                                            
  property :isNews          ,         :boolean                                                                                                            
  property :latestTitle     ,         :string                                                                                                          
  property :latestContent   ,         :clob                                                                                                                  
  property :latestVersion   ,         :unsigned_integer                                                                                                               
  property :geo             ,         :string            
  property :place_id        ,        :string                                                                                                            
  property :parent_id       ,         :string                                                                                                            
  property :AncestorPlace   ,         :string                                                                                                               
  property :isMessage       ,         :boolean                                                                                                            
  property :IsRead          ,         :boolean                                                                                                            
  property :IsAlbum         ,         :boolean                                                                                                            
  property :address , :string ,:is_encrypted=>false
  property :latitude        ,         :float         ,:is_encrypted=>false
  property :longitude       ,         :float          ,:is_encrypted=>false
  property :username        ,         :string
  property :page_gen_time   ,         :date                                                                                                  
  property :language_id     ,         :string                                                                                                  
  property :group_id        ,         :string                                                                                                               
  property :is_sterile      ,         :boolean                                                                                                            
  property :last_branch_update_time , :date                     
  index :public_channel,[:publicRead,:isChannel]
  index :public_language,[:publicRead,:language_id]
  index :username_public_read_and_is_channel,[:username,:publicRead,:isChannel]
  
  belongs_to :User ,:username, :author
  belongs_to :Node ,:parent_id, :parent
   
  belongs_to :Place,:AncestorPlace,:ancestor_place
  belongs_to :Place,:place_id,:place
  
  has_many :Node,:parent_id,:child_nodes,:tracking=>true
  def Node.fill_new_node(user_name,title,content)
    new_node=Node.new
    new_node.username=user_name.downcase
    new_node.latestTitle=title #HtmlUtility.sanitize_html( title)
    new_node.latestContent=content #HtmlUtility.sanitize_html( content)
    new_node.creationTime=Time.now.gmtime
    new_node.last_branch_update_time=new_node.creationTime
    new_node.publicRead=true
    new_node.publicWrite=false
    new_node.clicks=0
    new_node.isRss=false
    new_node.isNews=false
    new_node.clicks=false
    new_node.isMessage=false
    new_node.isChannel=false
    new_node.is_sterile=false

    return new_node
  end
  def children(order_by  = :last_branch_update_time,order=:descending)
    result=Node.find_by_parent_id(self.id)
    result.sort! do|a,b|
      if a.get_attribute(order_by)==nil and b..get_attribute(order_by)==nil
        b.creationTime <=> a.creationTime
      elsif a.get_attribute(order_by)==nil
        -1
      elsif b.get_attribute(order_by)==nil
        1
      else
        b.get_attribute(order_by)<=> a.get_attribute(order_by)
      end
    end
    result.reverse! if order==:ascending
    result
    
         
  end
  def child_count
    children.length
  end
  def get_nearby_features(zoom_level)
    return get_nearby(zoom_level)
  end
  def get_nearby_places(zoom_level)
    return Place.find_near(self.location,zoom_level)
  end
  def ancestor_place
    if !@ancestor_placeCached && self.AncestorPlace
      @ancestor_place_cache= Place.find(self.AncestorPlace)
      @ancestor_placeCached=true
    end
    return @ancestor_place_cache
  end
    
    
  def Album
    return Album.find_by_guid(self.album_guid)
            
  end
  def album_guid
    return "gc_node#{self.id}"
  end
  def mediaitems
            
    result=[]
    if self.Album
            
      result=self.Album.mediaitems
    end
    return result
  end
         
  def still_image_media
              
    result=[]
    if self.Album
              
      result=self.Album.still_image_media
    end
    return result
  end
  def video_media
              
    result=[]
    album=self.Album
    if album
              
      result=album.video_media
    end
    return result
  end
  def audio_media
              
    result=[]
    if self.Album
              
      result=self.Album.audio_media
    end
    return result
  end
  def url
    if self.isChannel
      return "/channels/#{id}"
    end
    return "/items/#{id}"
  end
  def user_url
    return User.url_for( self.username)
  end
  def post_comment_url
    return "/items/#{self.id.to_s}/addcomment"
  end
  def Node.all_recent(language_id=nil,how_many=64)
    result=find(:all,:limit=>how_many,:order=>:descending,:order_by => :creationTime)
     
  end      
  def Node.recent(language_id=nil,how_many=64)
    # #this query has been dumbed down to get bearable performance
    result=[]
    
    how_long_back=60*60*24*30
    result=find(:all,:limit=>1000,:order=>:descending,:order_by => :creationTime)
       
    if language_id
   
      result.collect!{|x|y=(x.language_id==language_id && x.publicRead)?x:nil}
    else
      result.collect!{|x|y=(x.publicRead )?x:nil}
     
    end
    result.compact!
    result.sort {|x,y| y.creationTime <=> x.creationTime }
    result=result[0..how_many-1] if result.length>how_many
   
    
       
    result
  end
        
  def Node.recent_public_for_user(user_login,how_many=20)
    # #TODO fix this
    # #Node.find_by_username_public_read_and_is_channel(user_login  ,true
    # ,false,:limit=>how_many,:order_by=>:creationTime,:order=>:descending)
    user_login=user_login.downcase
    if user_login=='david'

      # #this is thequery that should work for everyone but the index is corrupt
      # #have to use it for david because sdb can't handle david's dataset with
      # other query #Node.find_by_username_public_read_and_is_channel(user_login
      # ,true
      # ,false,:limit=>how_many,:order_by=>:creationTime,:order=>:descending)
      result=[]
    elsif      user_login=='system' || user_login=='guest' 
      # #these two have way to many nodes and shouldn't be linked to anyway
      result=[]
    else
      result=Node.find_by_username(user_login)
      # #tried many angles on this query.
      
    end
    result.collect!{|x|y=((x.publicRead==true or (x.publicRead==nil and x.group_id==nil)) && (x.isChannel==nil || x.isChannel==false))?x:nil}
    result.compact!
    result.sort {|x,y| y.creationTime <=> x.creationTime }
    result=result[0..how_many-1] if result.length>how_many
      
    result
  end
  def Node.recent_for_user(user_login,how_many=100)
    if user_login.downcase=='david' ||user_login.downcase=='system'  ||user_login.downcase=='david'
      return []
    end
    Node.find_by_username(user_login.downcase,:limit=>how_many,:order_by=>:creationTime,:order=>:descending)
  end
  def Node.channels_for_user(user_login,how_many=20)
    # #Node.find_by_username_public_read_and_is_channel(user_login.downcase
    # ,true ,true,:limit=>how_many,:order_by=>:creationTime,:order=>:descending)
    if user_login.downcase=='david' ||user_login.downcase=='system'  ||user_login.downcase=='david'
      return []
    end
    result=Node.find_by_username(user_login.downcase)
    result.collect!{|x|y=( x.isChannel==true)?x:nil}
    result.compact!
    result.sort {|x,y| y.creationTime <=> x.creationTime }
  end
  def Node.AddNode(user_name,parent_node_id,title,content)

    new_node=Node.fill_new_node(user_name,title,content)

    
    if parent_node_id!=nil 
      parent = Node.find(parent_node_id)
      if parent
        if parent.is_sterile 
          return
        end
        new_node.parent_id=parent.id
        new_node.AncestorPlace=parent.AncestorPlace
        new_node.geo=parent.geo
        new_node.latitude=parent.latitude
        new_node.longitude=parent.longitude
        new_node.address=parent.address
        new_node.isNews=parent.isNews
        new_node.isComment=true
      end
     
      
      ancestor=parent
      while ancestor
        ancestor.last_branch_update_time=new_node.last_branch_update_time
        ancestor.save!
        if ancestor.parent_id  
          ancestor=Node.find(ancestor.parent_id)
        else
          ancestor=nil
        end
      end
    end
    
    
    new_node.save!
   
    return new_node
  end
end
