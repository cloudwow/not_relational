require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class TagTest < Test::Unit::TestCase
  def TagTest.set_up
    
    #    Mediaitem.find(:all).each do |node|
    #      node.destroy
    #    end
    #    User.find(:all).each do |node|
    #      node.destroy
    #    end
    Tag.find(:all).each do |node|
      node.destroy
    end
    Group.find(:all).each do |node|
      node.destroy
    end
    
  end
  def test_find_by_group_and_tag
    TagTest.set_up
    group1=Group.create_group("testgroup", "my group short desc", "description long desc", "tags my test", true, 'joe')
    group2=Group.create_group("testgroup2", "my group short desc", "description long desc", "tags my test", true, 'joe')
    tag=Tag.new
    tag.tag_name='my'
    tag.group_id=group1.id
    tag.mediaitem_id='a'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='my'
    tag.group_id=group1.id
    tag.mediaitem_id='b'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id=group1.id
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id=group2.id
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.tag_name='duh'
    tag.group_id=group2.id
    tag.mediaitem_id='c'
    tag.created_time=Time.now.gmtime
    tag.save
    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache
    
    found=Tag.find_by_group_and_tag(group1.id,'my',:limit=>100,:order_by=>:tag_name,:order=>:descending)
    assert_equal(2,found.length)
    found=Tag.find_by_group_and_tag(group1.id,'duh',:limit=>100,:order_by=>:tag_name,:order=>:descending)
    assert_equal(1,found.length)
    found=Tag.find_by_group_and_tag(group2.id,'duh',:limit=>100,:order_by=>:tag_name,:order=>:descending)
    assert_equal(2,found.length)
  end
  
end
