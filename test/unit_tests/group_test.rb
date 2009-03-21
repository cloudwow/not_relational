
require 'rubygems'
require 'test/unit'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')
require File.dirname(__FILE__) +'/../../lib/not_relational/domain_model.rb'
require File.dirname(__FILE__) +'/../../lib/not_relational/attribute_range.rb'

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
require File.dirname(__FILE__) +'/../../test/models/user_event.rb'

ENV['NOT_RELATIONAL_ENV']='testing'
     
class GroupTest < Test::Unit::TestCase
  
  def GroupTest.set_up
    Mediaitem.find(:all).each do |node|
      node.destroy
    end
    Node.find(:all).each do |node|
      node.destroy
    end
    User.find(:all).each do |node|
      node.destroy
    end
    GroupMember.find(:all).each do |node|
      node.destroy
    end
    GroupInvite.find(:all).each do |node|
      node.destroy
    end
    GroupChannel.find(:all).each do |node|
      node.destroy
    end
    Group.find(:all).each do |node|
      node.destroy
    end
    
    Album.find(:all).each do |node|
      node.destroy
    end
    
  end
  
  def test_create_group
    GroupTest.set_up
    group1=Group.create_group("testgroupqw", "my group short desc", "description long desc", "tags my test", true, 'joe')
    group2=Group.create_group("testgroupqw", "my group short desc", "description long desc", "tags my test", true, 'joe')
    #second groups hould be same group
    assert_equal(group1.id,group2.id)
  end

  def test_members
    NotRelational::RepositoryFactory.instance.pause()
    GroupTest.set_up
    
   
     joe=User.new()
    joe.login='joe'
    joe.save
   
    group=Group.create_group("tkuuhestgroup", "my group short desc", "description long desc", "tags my test", true, 'joe')
found=group.members
     assert(found!=nil)
    assert_equal(1,found.length)
    assert_equal('joe',found[0].login)
    
     david=User.new()
    david.login='david'
    david.save
   
    NotRelational::RepositoryFactory.instance.pause()
    found=group.members
    assert_equal(1,found.length)
   
     
    group.add_member 'david'
    NotRelational::RepositoryFactory.instance.pause()
    
    found=group.members
     
    assert_equal(2,found.length)
  end


  def test_tag_cloud
    GroupTest.set_up
    group=Group.create_group("tiiestgroup", "my group short desc", "description long desc", "tags my my test", true, 'joe')
    
    tag=Tag.new
    tag.tag_name='my'
    tag.group_id=group.id
    tag.mediaitem_id='a'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='my'
    tag.group_id=group.id
    tag.mediaitem_id='b'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id=group.id
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id='not'
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id='abc'
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tags=group.tag_cloud
   
    assert_equal(2,tags.tags.length)
    assert_equal(2,tags.get_count('my'))
    assert_equal(1,tags.get_count('duh'))
  end

  def test_channel
    GroupTest.set_up
    group=Group.create_group("testgroupsdfwe", "my group short desc", "description long desc", "tags my my test", true, 'joe')
    NotRelational::RepositoryFactory.instance.pause()

    channel=group.channel
    assert_not_nil(channel)
  end

  def test_is_my_thread
    GroupTest.set_up
    group=Group.create_group("testgroup123", "my group short desc", "description long desc", "tags my my test", true, 'joe')
        NotRelational::RepositoryFactory.instance.pause()


    
    channel=group.channel
    assert_not_nil(channel)
    node= Node.fill_new_node('david', "title", 'hello world')
    node.parent_id=channel.id
    node.save!
    
    assert(group.is_my_thread(node))
  end

  def test_icon
    GroupTest.set_up
    group=Group.create_group("testgroup321", "my group short desc", "description long desc", "tags my my test", true, 'joe')
    item=Mediaitem.new
    item.guid='xx'
    item.save!
    group.icon_guid='xx'
    group.save
    NotRelational::RepositoryFactory.instance.pause()
    found=group.icon
    assert_not_nil(found)
    assert_equal(item.id,found.id)
  end

  def test_recent_events
    GroupTest.set_up
    group=Group.create_group("tluuestgroup", "my group short desc", "description long desc", "tags my my test", true, 'joe')
    events=[]
    (0..5).each do |i|
      event=UserEvent.new
      event.group_id=group.id
      event.event_time=Time.now.+i*50
      event.save
      events<<event
    end
    NotRelational::RepositoryFactory.instance.pause()
    found=group.recent_events
    
    assert_equal(6,found.length)
    
    assert_equal(events[5].id,found[0].id)
    assert_equal(events[4].id,found[1].id)
  end
  
  def test_albums
    GroupTest.set_up
    group=Group.create_group("tqweqwrestgroup", "my group short desc", "description long desc", "tags my my test", true, 'joe')
    album1=Album.create_group_album('joe',group.id,'title','description',false)
    album2=Album.create_group_album('dave',group.id,'title2','description2',false)
    album2.created_time_utc=Time.now.gmtime+50
    album2.save
         
    albums=group.albums
    
      assert_equal(2,albums.length)
    
    assert_equal(album2.id,albums[0].id)
    assert_equal(album1.id,albums[1].id)
  end
end
