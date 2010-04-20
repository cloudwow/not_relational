

require 'test/test_helper.rb'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')
require File.dirname(__FILE__) +'/../../test/models/node.rb'
require File.dirname(__FILE__) +'/../../test/models/user.rb'
require File.dirname(__FILE__) +'/../../test/models/user_event.rb'
require File.dirname(__FILE__) +'/../../test/models/place.rb'
require File.dirname(__FILE__) +'/../../test/models/album.rb'
require File.dirname(__FILE__) +'/../../test/models/media_item.rb'
require File.dirname(__FILE__) +'/../../test/models/media_file.rb'
require File.dirname(__FILE__) +'/../../test/models/tag.rb'
require File.dirname(__FILE__) +'/../../test/models/rating.rb'
require File.dirname(__FILE__) +'/../../test/models/comment.rb'
require File.dirname(__FILE__) +'/../../test/models/page_view_detail.rb'

ENV['NOT_RELATIONAL_ENV']='testing'
class AlbumTest < Test::Unit::TestCase
  def AlbumTest.set_up
    NotRelational::RepositoryFactory.instance.clear_session_cache

    PageViewDetail.find(:all).each do |node|
      node.destroy
    end
    Group.find(:all).each do |node|
      node.destroy
    end
    UserEvent.find(:all).each do |node|
      node.destroy
    end
    Album.find(:all).each do |node|
      node.destroy
    end
    Node.find(:all).each do |node|
      node.destroy
    end
    
    Mediaitem.find(:all).each do |node|
      node.destroy
    end
    
  end

  def test_item_before_after
    AlbumTest.set_up

    node_album=Album.new
    node_album.user_name='david'
    node_album.save
    mediaitems=[]
    (0..5).each do |i|
      mediaitem=Mediaitem.new
      mediaitem.title="mediaitem #{i}"
      mediaitem.created_time=Time.now+i*10
      mediaitem.save!
      node_album.connect_mediaitem(mediaitem)
      mediaitems << mediaitem
    end
    NotRelational::RepositoryFactory.instance.pause()
    found_items=node_album.mediaitems
    assert_equal(6,found_items.size)
    found_items=found_items.sort_by{|k|k.created_time}
    (0..5).each do |i|
      assert_equal(mediaitems[i].id,found_items[i].id)
    end
    found=node_album.item_before(mediaitems[2])
    assert(found!=nil)         
    assert_equal(mediaitems[1].id,found.id)
    
    found=node_album.item_before(mediaitems[5])
    assert(found!=nil)         
    assert_equal(mediaitems[4].id,found.id)
    
    found=node_album.item_before(mediaitems[0])
    assert(found==nil)         
    
    found=node_album.item_after(mediaitems[1])
    assert(found!=nil)         
    assert_equal(mediaitems[2].id,found.id)
    
    found=node_album.item_after(mediaitems[4])
    assert(found!=nil)         
    assert_equal(mediaitems[5].id,found.id)
    
    found=node_album.item_after(mediaitems[5])
    assert(found==nil)         
    
    
    
  end


  def test_recent


    AlbumTest.set_up
    
    node_album=Album.new
    node_album.save
    mediaitems=[]
    
    (0..5).each do | i|
      mediaitems[i]=Mediaitem.new
      mediaitems[i].title="mediaitem#{i.to_s}"
      mediaitems[i].created_time=Time.now+i*5
      mediaitems[i].save!
      
      node_album.connect_mediaitem(mediaitems[i])
    end
    
    NotRelational::RepositoryFactory.instance.pause()
    
    found=node_album.recent(3)
    assert(found!=nil)
    
    assert_equal(3,found.length)


    assert_equal(mediaitems[5].id,found[0].id)
    assert_equal(mediaitems[4].id,found[1].id)
    assert_equal(mediaitems[3].id,found[2].id)
  end
  
  def test_mediaitems
    AlbumTest.set_up
    
    node_album=Album.new
    node_album.save
    
    mediaitem1=Mediaitem.new
    mediaitem1.title="mediaitem1"
    mediaitem1.save!
    mediaitem2=Mediaitem.new
    mediaitem2.title="mediaitem2"
    mediaitem2.save!
    mediaitem3=Mediaitem.new
    mediaitem3.title="mediaitem3"
    mediaitem3.save!
    
    node_album.connect_mediaitem(mediaitem1)
    NotRelational::RepositoryFactory.instance.pause()
    
    found=node_album.mediaitems
    assert(found!=nil)
    
    assert_equal(1,found.length)
    assert_equal(mediaitem1.id,found[0].id)
    
  end
  
  def test_segmented_media
    AlbumTest.set_up
    node_album=Album.new
    node_album.user_name='david'
    node_album.save
    
    mediaitem1=Mediaitem.new
    mediaitem1.title="mediaitem1"
    mediaitem1.HasVideo=true
    mediaitem1.save!
    
    mediaitem2=Mediaitem.new
    mediaitem2.title="mediaitem1"
    mediaitem2.HasVideo=true
    mediaitem2.save!
    
    mediaitem3=Mediaitem.new
    mediaitem3.title="mediaitem1"
    mediaitem3.HasAudio=true
    mediaitem3.save!
    
    mediaitem4=Mediaitem.new
    mediaitem4.title="mediaitem1"
    mediaitem4.HasImage=true
    mediaitem4.save!
    
    #no flag means image
    mediaitem5=Mediaitem.new 
    mediaitem5.title="mediaitem1"
    mediaitem5.save!
    
    node_album.connect_mediaitem(mediaitem1)
    node_album.connect_mediaitem(mediaitem2)
    node_album.connect_mediaitem(mediaitem3)
    node_album.connect_mediaitem(mediaitem4)
    node_album.connect_mediaitem(mediaitem5)
    NotRelational::RepositoryFactory.instance.pause()
    
    found=node_album.video_media

    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node_album.still_image_media
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node_album.audio_media
    assert(found!=nil)         
    assert_equal(1,found.length)
  end
  def test_metadata
    a =Album.new
    a.user_name='david'
    a.metadata['x']='x1'
    a.metadata['y']='y1'
    a.save

    assert_equal(a.metadata['x'],'x1')
    assert_equal(a.metadata['y'],'y1')

    NotRelational::RepositoryFactory.instance.clear_session_cache
    NotRelational::RepositoryFactory.instance.pause()

    found=Album.find(a.id)
    assert_not_nil(found)
    assert_equal(found.user_name,'david')

    assert_not_nil(found.metadata)
    assert_equal(2,found.metadata.length)
    assert_equal(found.metadata['x'],'x1')
    assert_equal(found.metadata['y'],'y1')

  end
end
