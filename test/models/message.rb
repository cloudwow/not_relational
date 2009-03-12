require "uri"

require "not_relational/domain_model.rb"
class Message < NotRelational::DomainModel
    
  property :id,:string,:is_primary_key=>true
  property :title  , :string
  property :content  , :clob
  property :created_time_utc , :date
  property :from_user_name , :string
  property :to_user_name  , :string
 
  
  belongs_to :User,:from_user_name,:sender
  belongs_to :User,:to_user_name,:recipient
   def url
          return "/messages/#{self.id}"
  end
   def Message.recent(how_many=24)
      Message.find(:all,:limit=>how_many,:order_by =>:created_time_utc, :order=>:descending)
  end
  
    def Message.inbox(login,how_many=32)
      Message.find(:all,:limit=>how_many,:order_by =>:created_time_utc, :order=>:descending,:params=>{:to_user_name=>login})
    end
end
