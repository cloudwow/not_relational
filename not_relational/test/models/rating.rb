require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
class Rating < NotRelational::DomainModel
    
  
  property :id,:string,:is_primary_key=>true
  property :rating  , :integer
  property :created_at , :date
  property :mediaitem_id , :string
  property :user_name , :string
 
  
  belongs_to :Mediaitem
  
  
   

   
end
