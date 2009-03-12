require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
class Mediafile < NotRelational::DomainModel
    
     property :id,:string,:is_primary_key=>true
     property :mediaitem_id,:string
     property :mimeType,:string
     
     property :width,:unsigned_integer
     property :height,:unsigned_integer
     property :fileSize,:unsigned_integer
     property :bucket,:string
     property :guid,:string,:unique=>true
     
     belongs_to :Mediaitem
     
  
  
  
     def url
      return "http://s3.amazonaws.com/#{self.bucket}/media/#{self.guid}"
    end
     def view_url
       
      return "/media/#{self.mediaitem.guid}/#{width}x#{height}/show.html"
    end
   
    
   
end
