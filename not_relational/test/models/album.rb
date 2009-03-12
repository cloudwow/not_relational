require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
require "active_support/inflector"

class Album < NotRelational::DomainModel
  property :id,:string,:is_primary_key=>true
  property :guid , :string,:unique=>true
  property :user_name , :string
  property :title , :string
  property :description , :clob 
  property :created_time_utc ,:date  
  property :last_update_time_utc ,:date  
  property :is_private, :boolean
  property :group_id, :string

  index :group_and_title ,[:group_id,:title],:unique=>true
  many_to_many :Mediaitem,:AlbumMediaItem,:album_id,:mediaitem_id,:mediaitems,:order_by=>:created_time
  belongs_to :Group
  
     def Album.add_mediaitem(user_name,media_guid,album_guid,new_album_title=nil)
  
        mediaitem=Mediaitem.find_by_guid(media_guid)
        if mediaitem
            album=get_or_make_album(user_name,album_guid,new_album_title)
 
              album.add_mediaitem(mediaitem)
          
            return album
        end
        return nil
    end
    def still_image_media
      result=[]
      for media_item in self.mediaitems
        if !media_item.HasVideo && ! media_item.HasAudio
          result<<media_item;
        end
      end
        
      return result
    end
    def video_media
      result=[]
      for media_item in self.mediaitems
        if media_item.HasVideo 
          result<<media_item;
        end
                  
      end
      return result
    end
    def audio_media
      result=[]
      for media_item in self.mediaitems
        if media_item.HasAudio
          result<<media_item;
        end
      
      end
    
      return result
    end
    def  Album.create_group_album(user_name,group_id,title,description,is_private)
          
        album=Album.new
        album.guid="#{NotRelational::UUID.generate.to_s}"
        album.title=title
        album.user_name=user_name
        album.group_id=group_id
        album.description=description
        album.is_private=is_private
        album.created_time_utc=Time.now.gmtime
        album.save!
      
    
        return album
    end
    def item_after(mediaitem)
      previous=nil
      for child in self.mediaitems
        if previous && previous.id==mediaitem.id
         return child
        end
        previous=child
      end
            
    
            
      return nil
    end
        
  
    
    def item_before(mediaitem)
      
      previous=nil
     
      self.mediaitems.each do |child|
        if previous && child.id==mediaitem.id
          return previous
        end
                
        previous=child
      end
      
      return nil
    end
    def recent(how_many=5)
      result=self.mediaitems.reverse
      if result.length>how_many
        result=result.slice(0,how_many)
      end
      return result;
    end
    
    def url
      if group_id
        raise "can't generate group urls from this API"
      end
      return "album/#{guid}/show.html"
    end
    def create_group_url(group_name)
      return "#{Group.url_from_name(group_name)}/album/#{guid}"
    end
    def Album.create_group_url(group_name,album_guid)
      return "#{Group.url_from_name(group_name)}/album/#{album_guid}"
    end
    
    def create_group_edit_url(group_name)
      return "#{create_group_url(group_name)}/edit"
    end
    def create_group_upload_url(group_name)
      return "#{Group.url_from_name(group_name)}/album/#{guid}/upload"
    end
    def add_mediaitem(mediaitem)

        self.last_update_time_utc=Time.now.gmtime
        self.save           
 
       old_item=AlbumMediaItem.find_connection(self.id,mediaitem.id)
            if !old_item
                newAlbumMediaItem=AlbumMediaItem.new
                newAlbumMediaItem.album_id=self.id
                newAlbumMediaItem.mediaitem_id=mediaitem.id
                newAlbumMediaItem.save
                
            end

    end
      def Album.get_user_album(user_name,album_guid=nil)
        if !album_guid
            album_guid="useralbum:#{user_name}";
        end
        album=Album.find_by_guid(album_guid)
        if !album
            album=Album.new
            album.guid=album_guid
            album.user_name=user_name
            album.created_time_utc=Time.now.gmtime
            album.title="#{user_name.capitalize}'s media collection";
            album.save
        end
        if album.user_name!=user_name and   album.user_name!= h(user_name)
            raise "only album owner can submit to album"
        end
        return album
    end
    def  Album.get_or_make_album(user_name,album_guid,new_album_title=nil)
          
        if album_guid
            album=Album.find_by_guid(album_guid)
        end 
        if !album
            album=Album.new
               
            if album_guid
                album.guid=album_guid
            else
                album.guid="#{UUID.generate.to_s}"
            end
            
                 
                
            album.title=HtmlUtility.sanitize_html(new_album_title || "#{user_name.Capitalize}'s Media Collection").strip
            album.user_name=user_name
            album.created_time_utc=Time.now.gmtime
      
            album.save!
           
        end
        return album
    end
    
end
class AlbumMediaItem < NotRelational::DomainModel
    property :id,:string,:is_primary_key=>true
    property :album_id , :string
    property :mediaitem_id , :string
    index :album_and_mediaitem,[:album_id,:mediaitem_id],:unique=>true
    def AlbumMediaItem.find_connection(album_id,mediaitem_id)
      AlbumMediaItem.find_by_album_and_mediaitem(album_id,mediaitem_id)
    end
    
end