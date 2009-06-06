require 'digest/sha1'
require "uri"

require 'geo.rb'
require 'or_condition.rb'
require 'domain_model.rb'


class Place< NotRelational::DomainModel
  extend NotRelational::Geo::Locatable
  include NotRelational::Geo::Locatable
  property :id,:string,:is_primary_key=>true
  property :latitude        ,         :float                                                                                                                 
  property :longitude       ,         :float                                                      
  property :address , :string
  property :name , :string
  property :area_id , :string
  property :place_type_id , :string
  property :clicks , :unsigned_integer
  property :dim , :unsigned_integer
  property :last_activity , :date
  property :page_gen_time , :date
       
  has_many :Node
  has_many :Node,:AncestorPlace,:descendant_nodes
  #belongs_to :area
  #belongs_to :place_type
         
         def get_nearby_features(zoom_level)
            return get_nearby(zoom_level)
        end
        def get_nearby_nodes(zoom_level)
            return Node.find_near(self.location,zoom_level)
        end
        def album_guid
            return "gcplace-"+self.id.to_s
        end
        def Album
             return Album.find(:first,:params => {:guid=>self.album_guid})
       
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
            if self.Album
              result=self.Album.video_media
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
            return "/places/#{id}"
        end
        def i_live_here_url
          return "/profile/i_live_here/place/#{self.id.to_s}"
        end
        def post_comment_url
          return "/places/#{self.id.to_s}/addcomment"
        end
        def post_media_url
          return "/places/#{self.id.to_s}/addmedia"
        end
       
   def Place.convert_arg_to_place(place_arg)
      place=nil
     if place_arg.respond_to?(:name)
      place= place_arg
    else
      place=Place.find(place_arg)
    end
    return place
  end
  
  
end
