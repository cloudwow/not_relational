require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
class UserEvent < NotRelational::DomainModel
    
    property :id ,:string,:is_primary_key=>true
    property :login,:string
    property :blurb ,:string
    property :arguments ,:string
    property :event_time ,:date
    property :is_private ,:boolean
    property :is_read ,:boolean
    property :group_id ,:string
    belongs_to :Group
    belongs_to :User,:login
    index :login_and_is_private,[:login,:is_private]
    index :login_is_read_and_is_private,[:login,:is_read,:is_private]
    
   def UserEvent.recent_public_for_user(login,how_many=10)
     UserEvent.find_by_login_and_is_private(login,false,:limit=>how_many,:order_by=>:event_time,:order=>:descending)
   end
    def UserEvent.recent_for_user(login,how_many=10)
     UserEvent.find(:all,:limit=>how_many,:order_by=>:event_time,:order=>:descending, :conditions => {:login=>login})
   end
     def UserEvent.recent_public(how_many=10)
     UserEvent.find(:all,:limit=>how_many,:order_by=>:event_time,:order=>:descending, :params=>{ :is_private=>false})
   end
   def UserEvent.unread_events_for_user(login,how_many=24)
      
     UserEvent.find_by_login_is_read_and_is_private(login,false,true,:limit=>how_many,:order_by=>:event_time,:order=>:descending)
      
        
    end
    def mark_all_read_for_user(login)
      unread_events_for_user(login).each do |event|
        event.is_read=true
        event.save!
      end
    end
    def UserEvent.log_event(user_arg,group_arg,blurb,is_private,arguments)
      event=UserEvent.new
      if user_arg
        user=User.convert_arg_to_user(user_arg)

        event.login=user.login
      end

      if group_arg
        group=Group.convert_arg_to_group(group_arg)    
        event.group_id=group.id
      end

      event.blurb=blurb
      event.is_read=false


        if arguments        
          event.arguments=arguments.to_yaml    
      else
          event.arguments={}.to_yaml
      end
      event.is_private=is_private
      event.event_time=Time.now.gmtime
      event.save
    end
end
