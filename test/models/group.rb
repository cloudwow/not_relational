require 'digest/sha1'
require "uri"
require "tag.rb"

class Group < NotRelational::DomainModel
    encrypt_me
  property :id,:string,:is_primary_key=>true
  property :name , :string,:unique=>true
  property :normalized_name , :string,:unique=>true
  property :creator , :string
  property :creation_date , :date
  property :description , :string
  property :is_public , :boolean
  property :short_description , :string
  property :icon_guid , :string
  property :tags , :string
  property :layout , :text
  property :domain , :string,:unique=>true
  
  property :devpay_user_token , :string
  property :devpay_bucket , :string
  
  
  has_many :GroupInvite
  has_many :GroupMember,:group_id ,:group_members,:order_by => :member_login
  has_many :GroupChannel
  has_many :Album,:group_id,:albums,:order=>:descending,:order_by=>:created_time_utc
  has_many :MediaItem,:group_id,:media_items,:order=>:descending,:order_by=>:created_time
  many_to_many :Node,:GroupChannel,:group_id,:node_id,:channels
   
    
  
    
  def Group.create_group(name,short_description,description,tags,is_public,creator_login)

    group=Group.find_by_normalized_name(name)
    if !group
      group=Group.new
      group.name=name
      group.description=description
      group.short_description=short_description
      group.is_public=is_public
      group.creator=creator_login
      group.creation_date=Time.now.gmtime
      group.tags=tags
      group.save!
          
      channel_node=Node.fill_new_node(creator_login,name+" Discussion","")
      channel_node.isChannel=true
      channel_node.publicRead=false
      channel_node.publicWrite=false
      channel_node.save!

      group_channel=GroupChannel.new
      group_channel.node_id=channel_node.id
      group_channel.group_id=group.id
      group_channel.save

      group.add_member(creator_login)
    end
    return group
  end
  def add_member(login)
    member=GroupMember.find_by_group_and_login(self.id,login)
    if ! member
      member=GroupMember.new
      member.group_id=self.id
      member.member_login=login
      member.save!
#      @accessor_cache.delete(:group_members)
    end
    
    return member
  end
  def members
    result=[]
    for member in self.group_members
      member_user=User.find(member.member_login)
      result<< member_user if member_user
    end
    return result;
  end
  def Group.url_from_name(name)
    "/groups/"+URI.escape(name.capitalize, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
  def Group.create_thread_form_url_from_name(name)
    Group.url_from_name(name)+"/forum/create_thread_form"
  end
  def Group.create_thread_url_from_name(name)
    Group.url_from_name(name)+"/forum/create_thread"
  end
  def Group.show_thread_url_from_name(name,thread_id)
    return Group.url_from_name(name)+"/thread/#{thread_id}"
  end
   def Group.domained_groups
      Group.find(:all,:params=>{:domain=>:NOT_NULL})
    end
  def url
    Group.url_from_name(self.name)
  end
  def tag_url(tag_name)
    self.url+"/tag/"+URI.escape(tag_name.downcase, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
  def members_url
    self.url
  end
  def Group.forum_url_from_name(name)
    Group.url_from_name(name)+"/forum"
  end
  def forum_url
    Group.forum_url_from_name(self.name)
  end
  def invite_url
    self.url+"/invite"
  end
  def create_album_url
    Group.create_album_url_from_name(self.name.downcase)
  end
  def Group.create_album_url_from_name(name)
    Group.url_from_name(name)+"/create_album"
  end
     
  def create_event_url
    self.url+"/create_event"
  end
  def create_thread_url
    Group.create_thread_url_from_name(self.name.downcase)
  end
  def show_thread_url(thread_id)
    return Group.show_thread_url_from_name(self.name,thread_id)
  end
     
  def create_thread_form_url
    Group.create_thread_form_url_from_name(self.name.downcase)
  end
  def join_url
         
    self.url+"/join_public"
  end
  def join_with_invitation_url(token,language=nil)
    domain=self.domain || "globalcoordinate.com"
    if language 
      domain=language+"."+domain
    end
    return "http://"+domain+self.url+"/join/"+token
  end
  def news_feed_url
    self.url+"/news_stream"
  end
  def members_url
    self.url+"/members"
  end
  def albums_url
    self.url+"/albums"
  end
  def create_invite(email_address)
       
    invite=GroupInvite.new
    invite.token="#{NotRelational::UUID.generate.to_s}"
    invite.group_id=self.id
    invite.email_address=email_address
    invite.save!
    return invite
  end
  def tag_cloud
    tag_cloud=TagCloud.new(Tag.find_group_media_tags(self.id ))
   
  end
  def channel
    temp=channels
    return nil if temp.length==0
    return temp[0]
  end
  def is_my_thread(thread_node)
    return thread_node.parent_id==channel.id
        
        
  end
  def icon
    if self.icon_guid
      return Mediaitem.find(:first,:params=>{:guid=>self.icon_guid})
    end
  end
  @cached_events=nil
  def recent_events(how_many=32)
    
    UserEvent.find(:all,:limit=>how_many,:order=>:descending,:order_by=>:event_time,:params=>{:group_id=>self.id})
    
        
  end
  def Group.find_by_normalized_name(value)
    find(:first,:params=>{:normalized_name=>value.capitalize})
    
  end
  def Group.find_by_name(value)
    Group.find_by_normalized_name(value)
    
  end
  def name=(value)
    self.normalized_name=value
    super(value)
  end
  def normalized_name=(value)
    value=value.capitalize
    super(value)
  end
  def Group.convert_arg_to_group(group_arg)
    return nil unless group_arg
    group=nil
    if group_arg.respond_to?(:name)
      group=group_arg
    else
      group=Group.find_by_normalized_name(group_arg)
    end
    return group
  end
  def is_member?(login)
    member=GroupMember.find_by_group_and_login(self.id,login)
    return member!=nil
            
  end
  def create_thread(author,title,content)
    channel=self.channels[0]
      
    new_node=Node.fill_new_node(author,title,content)
    new_node.parent_id=channel.id
    new_node.publicRead=false
      
    new_node.group_id=self.id
    # new_node.is_private=true
    new_node.save!
    new_node
  end
  def post_to_thread(  author_login,thread_id,content)
       
    
    channel=self.channels[0]
    thread=Node.find(thread_id)
    author=User.find(author_login)
    return if thread.parent_id!=channel.id
    new_node=Node.fill_new_node(author.login,"re: "+thread.latestTitle,content)
    new_node.parent_id=thread.id
    new_node.is_sterile=true;
    new_node.isNews=false
    new_node.publicRead=false
    new_node.group_id=self.id
    new_node.save! 
      
    thread.last_branch_update_time=new_node.last_branch_update_time
    thread.save!
    channel.last_branch_update_time=new_node.last_branch_update_time
    channel.save!
  end
end
class GroupChannel < NotRelational::DomainModel
  property :id,:string,:is_primary_key=>true
  property :group_id,:string
  property :node_id,:string
  belongs_to :Group
  belongs_to :Node
end
class GroupMember < NotRelational::DomainModel
  property :id,:string,:is_primary_key=>true
  property :group_id,:string
  property :member_login,:string
  belongs_to :Group
  belongs_to :User,:member_login,:member
  index :group_and_login,[:group_id,:member_login],:unique=>true
end
class GroupInvite < NotRelational::DomainModel
  property :id,:string,:is_primary_key=>true
  property :group_id,:string
  property :expiration_time,:date
  property :redeemed_by_login,:string
  property :redeemed_time,:date
  property :outgoing_email_id,:string
  property :token,:string,:unique=>true
  property :email_address,:string
  
  belongs_to :Group
  belongs_to :OutgoingEmail,:outgoing_email_id
end
