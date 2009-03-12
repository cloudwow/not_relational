require 'digest/sha1'
require "uri"

require "model/domain_model.rb"
require "models/blurb.rb"

class Friend < DomainModel
  property :id,:string,:is_primary_key=>true
   property :user_name,:string
   property :friend_user_name,:string
   property :created_time_utc,:date
 belongs_to :User,:user_name,:user
 belongs_to :User,:friend_user_name,:friend
 index :user_name_and_friend_name,[:user_name,:friend_user_name],:unique=>true
  def Friend.make_friend(user_name,friend_name)
    existing_friend=Friend.find_by_user_name_and_friend_name(user_name.capitalize ,friend_name.capitalize)
    if existing_friend==nil
     newFriend=Friend.new
        newFriend.user_name=user_name
        newFriend.friend_user_name=friend_name
        newFriend.created_time_utc=Time.now.gmtime
        newFriend.save
      return true
    end
      return false
  end
end