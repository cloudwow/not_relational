require 'digest/sha1'
require "uri"
require 'not_relational/geo.rb'
require "not_relational/domain_model.rb"
require File.dirname(__FILE__) +"/node.rb"
require File.dirname(__FILE__) +"/message.rb"
require File.dirname(__FILE__) +"/group.rb"

class User  < NotRelational::DomainModel
    
    property :login ,:string,:is_primary_key=>true,:unique=>true,:required=>true
    property :crypted_password ,:string,:required=>true
    property :created_at ,:date,:required=>true
    property :salt ,:string,:required=>true
    property :remember_token ,:string
    property :remember_token_expires_at ,:date
    property :last_login,:date
    property :profile_mediaitem_guid,:string
    property :blurb,:clob
    property :album_guid,:string
    property :email,:string
    property :is_translater,:boolean
    property :place_id,:string
    property :latitude,:float
    property :longitude,:float
    property :address,:string
    property :diary_channel_id,:string
    
    extend NotRelational::Geo::Locatable
    include NotRelational::Geo::Locatable
    
    has_many :Node,:username,:nodes
   has_many :Message,:from_user_name,:sent_messages
  has_many :Message,:to_user_name,:recieved_messages
  has_many :Comment,:user_name,:comments
  has_many :Tag,:user_name,:tags
  
    def User.table_name
        return "User2"
    end
    def validate
        if !login || login.length<1
            return false
        end
        
        if ! /^[a-z]{2}(?:\w+)?$/i.match(login) # , :message=>'<i>Only letters(a-z), numbers(0-9), underscores(_) are allowed.</i>'
            return false
        end
         if !password || password.length<5
            return false
        end
        
        return true
    end
  
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  

  def authenticated?(password)
    result=crypted_password == encrypt(password,self.salt)
    return result
  end

  def remember_token?
      if respond_to?(:remember_token_expires_at) 
         self.remember_token_expires_at &&  Time.now.utc < Time.parse(self.remember_token_expires_at) 
      end
      return false
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc.to_s
    self.remember_token            = encrypt("#{self.login}--#{self.remember_token_expires_at}",self.salt)
   
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
   
  end

   
   
    def User.find_by_remember_token(token)
        User.find(:first,:repository=>$repository,:params=>{:remember_token=>token})
 
    end
    def find(*arguments)
        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}
        if !scope
          return nil
        end
        case scope
          when :all   then return find_every(options)
          when :first then return find_every(options).first
          else             return find_single(scope.downcase, options)
        end
      end
     def User.recent_with_media(how_many=24)
       #this gets cal
 #   users=User.find(:all,:order_by=>:created_at,:order=>:descending,:limit=>how_many,:params=>{:profile_mediaitem_guid=>:NOT_NULL})
 
       users=User.find(:all,:order_by=>:created_at,:order=>:descending,:limit=>1200)
       
       
       users.collect!{|x|
         y=(x.profile_mediaitem_guid!=nil && x.profile_mediaitem_guid.length>0) ?x:nil
         
       }
       
       
       users.compact!
       users.sort {|x,y| y.created_at <=> x.created_at }
       if users.length>how_many
         users=users[0..how_many-1]
       end
       return users
     end
    
   
    def save(options={})
         self.login=self.login.downcase
         super(options)
      
    end
    
     def set_password(password)
      
      return if password.blank?
      self.salt= Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") 
      self.crypted_password= encrypt(password,salt)
    end
 
     def User.tiny_square_profile_url(login)
       "http://#{$media_bucket}.s3.amazonaws.com/users/#{login.downcase}/profile_tiny_square.jpeg"
     end
     def User.square_profile_url(login)
       "http://#{$media_bucket}.s3.amazonaws.com/users/#{login.downcase}/profile_square.jpeg"
     end
     def uri_login
       User.uri_login( self.login.downcase)
     end
     def User.uri_login(login)
       URI.escape( login.downcase, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")  )
     end
      def tiny_square_profile_url
       "http://#{$media_bucket}.s3.amazonaws.com/users/#{uri_login}/profile_tiny_square.jpeg"
     end
     def square_profile_url
       "http://#{$media_bucket}.s3.amazonaws.com/users/#{uri_login}/profile_square.jpeg"
     end
      def profile_media
      if self.profile_mediaitem_guid
       return Mediaitem.find_by_guid(self.profile_mediaitem_guid)
      end
      
         return nil;             
    end
    def inbox
      return Message.inbox(self.login)
    end
    def User.sent_messages
      Message.find_by_from_user_name(self.login)
    end
    def User.url_for(login)
      return "/users/#{URI.escape( login.downcase, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    end
   def  User.home_directory_for(login)
      return User.url_for(login)
    end
    def  User.send_message_url_for(login)
      return "#{User.url_for(login)}/send_message_form"
    end
    def  User.apply_friend_url_for(login)
      return "#{User.url_for(login)}/apply_friend_form"
    end
    
    def url
      return User.url_for( self.login)
    end
   def home_directory
      return User.home_directory_for( self.login)
    end
    def send_message_url
      return User.send_message_url_for(self.login)
    end
      def apply_friend_url
      return User.apply_friend_url_for(self.login)
    end
   
    def album_guid
      return "useralbum:#{self.login}"
    end
    def get_groups
        result=[]
        for group_member in GroupMember.find(:all,:params=>{:member_login=>login}) 
            group=group_member.group
            if group
              result << group_member.group
            end
        end
        
      result.sort! do |x,y|       
         x.name<=> y.name
      end
      
      return result
    end
      
     def unread_events
        UserEvent.unread_events_for_user(self.login)
    end
    def on_activity
      self.last_login=Time.now.gmtime
      self.save!
    end
    def get_user_album
     return Album.get_user_album(self.login)
    end
     
   
    def url
      return "/users/#{CGI.escape login}"
    end
    
    def friends
      friend_data= Friend.find(:all,:order_by=>:friend_user_name, :params => {:user_name=>self.login})
      result=[]
      for friend_record in friend_data
        friend_user=User.find(friend_record.friend_user_name)
        result << friend_user if friend_user
      end
      return result;
    end
    
    def friend_requests_incoming
      return FriendRequest.find_by_user_name_and_answer_is_null(self.login,true,:order_by => :created_time_utc)
    end
    
    def friend_requests_outgoing
      
        return FriendRequest.find_by_friend_name_and_answer_is_null(self.login,true,:order_by => :created_time_utc)
    
    end
    
  def tag_url(tag_name)
    self.url+"/tag/"+URI.escape(tag_name.downcase, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
    def tag_cloud
      TagCloud.new(Tag.find_by_user_name(self.login))   
    end
    def get_or_create_user_diary_id()
      if self.diary_channel_id
        return self.diary_channel_id
      end
       node=Node.fill_new_node(self.login,self.login.capitalize+"'s diary","")
     node.isChannel=true
     node.publicRead=true
     node.publicWrite=false
     node.save!
     self.diary_channel_id=node.id;
     self.save!
     return node.id
     
  end
    def User.convert_arg_to_user(user_arg)
      user=nil
     if user_arg.respond_to?(:remember_me)
      user=user_arg
    else
      user=User.find(user_arg.downcase)
    end
    return user
  end
end
