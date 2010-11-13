
require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class AlbumTest < Test::Unit::TestCase


  def test_update_cache_on_write
    Mediaitem.all.each{|m|m.destroy}
    mediaitems=[]
    5.times do |i|
      mediaitem=Mediaitem.new
      mediaitem.title="mediaitem #{i}"
      mediaitem.save!
      mediaitems << mediaitem
    end

    NotRelational::RepositoryFactory.instance.clear_session_cache
    NotRelational::RepositoryFactory.instance.pause()

    found=Mediaitem.find(:all,:order_by=>:title)
    assert_equal(5,found.length)
    assert_equal("mediaitem 0",found[0].title)
    found_single=Mediaitem.find(found[0].id)
    assert_equal("mediaitem 0",found_single.title)

    found[0].title="duh"
    found[0].save!

    
    found=Mediaitem.find(:all,:order_by=>:title)
    assert_equal(found.length,5)
    assert_equal("duh",found[0].title)
    

    found_single=Mediaitem.find(found[0].id)
    assert_equal("duh",found_single.title)

  end

  def test_destroy


    mediaitems=[]
    5.times do |i|
      mediaitem=Mediaitem.new
      mediaitem.title="mediaitem #{i}"
      mediaitem.save!
      mediaitems << mediaitem
    end

    mediaitems.each do |m|
      m.destroy
      found=Mediaitem.find(m.id)
      assert_nil(found)
    end

  end
  
end
