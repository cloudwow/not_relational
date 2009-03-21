require 'digest/sha1'
require "uri"

require "model/domain_model.rb"
require "models/blurb.rb"

class FriendRequest < DomainModel
  property :id,:string,:is_primary_key=>true
   property :user_name,:string
   property :friend_user_name,:string
   property :message,:text
   property :answer,:boolean
   property :created_time_utc,:date
 belongs_to :User,:user_name,:user
 belongs_to :User,:friend_user_name,:friend_user
 index :user_name_friend_name_and_answer_is_null,[:user_name,:friend_user_name,IsNullTransform.new(:answer)],:unique=>true
 index :user_name_and_answer_is_null,[:user_name,IsNullTransform.new(:answer)]
 index :friend_name_and_answer_is_null,[:friend_user_name,IsNullTransform.new(:answer)]
  def FriendRequest.request_friendship(from_user_name,to_user_name,message)
    old_request=    find_old_request(from_user_name,to_user_name)
   return false if old_request!=nil
    new_request=FriendRequest.new
    new_request.user_name=from_user_name
    new_request.friend_user_name=to_user_name
    new_request.message=message
    new_request.created_time_utc=Time.now.gmtime
    new_request.save
    return true
  end
  def FriendRequest.find_old_request(from_user_name,to_user_name)
      FriendRequest.find_by_user_name_friend_name_and_answer_is_null(from_user_name,to_user_name,true)
  end
  
end