require "uri"

require "not_relational/domain_model.rb"
class Comment < NotRelational::DomainModel
    
  property :id,:string,:is_primary_key=>true
  property :title  , :text
  property :content  , :text
  property :posted_time , :date
  property :mediaitem_id , :string
  property :parent_id  , :string
  property :user_name , :string
  property :namespace , :string
 
  
  belongs_to :Mediaitem
  
    def Comment.recent
        Comment.find(:all, :limit => 16 ,:order_by =>:posted_time ,:order => :descending)
  end
    def Comment.recent_by_user(user_name)
      Comment.find(:all, :limit => 16 ,:order_by =>:posted_time ,:order => :descending,:params => {:user_name=>user_name})
    end
   def user_url
      return "/users/#{CGI.escape self.user_name}"
    end
end
