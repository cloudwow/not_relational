
require 'rubygems'
require 'test/unit'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')
require File.dirname(__FILE__) +'/../../lib/not_relational/domain_model.rb'
require File.dirname(__FILE__) +'/../../lib/not_relational/attribute_range.rb'
require File.dirname(__FILE__) +'/../../lib/not_relational/repository.rb'
require File.dirname(__FILE__) +'/../../lib/not_relational/memory_repository.rb'
require File.dirname(__FILE__) +'/../../test/models/node.rb'
require File.dirname(__FILE__) +'/../../test/models/user.rb'
require File.dirname(__FILE__) +'/../../test/models/place.rb'
require File.dirname(__FILE__) +'/../../test/models/album.rb'
require File.dirname(__FILE__) +'/../../test/models/media_item.rb'
require File.dirname(__FILE__) +'/../../test/models/media_file.rb'
require File.dirname(__FILE__) +'/../../test/models/tag.rb'
require File.dirname(__FILE__) +'/../../test/models/rating.rb'
require File.dirname(__FILE__) +'/../../test/models/comment.rb'
require File.dirname(__FILE__) +'/../../test/models/blurb.rb'

ENV['not_relational_ENV']='testing'

 class UserTest < Test::Unit::TestCase
  def test_range
     User.find(:all).each do |old_user |
        old_user.destroy
    end
      blurb_1=Blurb.new(:name=>"garbage_1")
       blurb_1.save
       blurb_2=Blurb.new(:name=>"garbage_2")
       blurb_2.save
      
       
     @user1 = User.new(
               :login=>'aaa',
               :last_login => Time.now.gmtime,
               :created_at => Time.now.gmtime,
               :password=>"guid2",
               :profile_mediaitem_guid=>"duh1"
              )
              
    @user1.save
     @user2 = User.new(
               :login=>'ccc',
               :last_login => Time.now.gmtime,
               :created_at => Time.now.gmtime,
               :profile_mediaitem_guid=>"guid1"
              )
    @user2.save
    
   @user3 = User.new(
               :login=>'ddd',
               :last_login => Time.now.gmtime,
               :created_at => Time.now.gmtime-200*60*60
              )
    @user3.save
    
        NotRelational::RepositoryFactory.instance.pause()
  results=User.recent_with_media()  
       
      assert_equal( 2 , results.length )
        
   end
#  def test_trackers
#  User.find(:all).each do |old_user |
#        old_user.destroy
#    
#  end
#  Node.find(:all).each do |old_node |
#        old_node.destroy
#    end
#    user=nil
#    node=nil
#    DomainModel.transaction{
#     user = User.new(
#               :login=>'aaa',
#               :last_login => Time.now.gmtime,
#               :created_at => Time.now.gmtime,
#               :password=>"guid2",
#               :profile_mediaitem_guid=>"duh1"
#              )
#              
#    user.save
#    user.save
#    user.save
#    node=  Node.fill_new_node(user.login, "my title", 'hello world')
#    user.add_to_nodes(node)
#    }
#  found=user.nodes
#  assert_equal(1,found.length)
#  
#  assert_equal(node.id,found[0].id)
#  
#   user=User.find(user.login)     
#   
#    found=user.nodes
#  assert_equal(1,found.length)
#  
#  assert_equal(node.id,found[0].id)
# end
 
 end