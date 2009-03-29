
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

ENV['NOT_RELATIONAL_ENV']='testing'
     
class MediaItemTest < Test::Unit::TestCase
  def MediaItemTest.set_up
    Node.find(:all).each do |node|
      node.destroy
    end
    Place.find(:all).each do |node|
      node.destroy
    end
    Album.find(:all).each do |node|
      node.destroy
    end
    Mediaitem.find(:all).each do |node|
      node.destroy
    end
     Mediafile.find(:all).each do |node|
      node.destroy
    end
    User.find(:all).each do |node|
      node.destroy
    end
    Tag.find(:all).each do |node|
      node.destroy
    end
    Rating.find(:all).each do |node|
      node.destroy
    end
    Comment.find(:all).each do |node|
      node.destroy
    end
       
  end
  def test_destroy_dependent_tags
   MediaItemTest.set_up
   item=Mediaitem.new
    item.save
    tag=Tag.new
    tag.created_time=Time.now.gmtime
    tag.mediaitem_id=item.id
    tag.save
     
    tag=Tag.new
    tag.mediaitem_id=item.id
    tag.created_time=Time.now.gmtime
    tag.save
    
    tag=Tag.new
    tag.save
    
    NotRelational::RepositoryFactory.instance.pause()
    all_tags=Tag.find(:all)
    assert(all_tags.length==3)
    item.destroy
    NotRelational::RepositoryFactory.instance.pause()
    all_tags=Tag.find(:all)
    assert(all_tags.length==1)
  end
   def test_destroy_dependent_ratings
      MediaItemTest.set_up
 item=Mediaitem.new
    item.save
    tag=Rating.new
    tag.mediaitem_id=item.id
    tag.save
     
    tag=Rating.new
    tag.mediaitem_id=item.id
    tag.save
    
    tag=Rating.new
    tag.save
    NotRelational::RepositoryFactory.instance.pause()
    
    all_tags=Rating.find(:all)
    assert(all_tags.length==3)
    item.destroy
    NotRelational::RepositoryFactory.instance.pause()
    all_tags=Rating.find(:all)
    assert(all_tags.length==1)
  end
   def test_destroy_dependent_comments
     MediaItemTest.set_up
  item=Mediaitem.new
    item.save
    tag=Comment.new
    tag.mediaitem_id=item.id
    tag.save
     
    tag=Comment.new
    tag.mediaitem_id=item.id
    tag.save
    
    tag=Comment.new
    tag.save
    
    NotRelational::RepositoryFactory.instance.pause()
    all_tags=Comment.find(:all)
    assert_equal(3,all_tags.length)
    item.destroy
    NotRelational::RepositoryFactory.instance.pause()
    all_tags=Comment.find(:all)
    assert_equal(1,all_tags.length)
  end
  def test_recent
     MediaItemTest.set_up
  items=[]
    (0..5).each do |i|
      item=Mediaitem.new
      item.created_time=Time.now+i*100
      item.save
      items<<item
    end
    
    found=Mediaitem.recent(3)
    assert_equal(3,found.length)
    assert_equal(items[5].id,found[0].id)
    assert_equal(items[4].id,found[1].id)
    assert_equal(items[3].id,found[2].id)
    
  found=Mediaitem.recent(20)
   
    assert_equal(6,found.length) 
    assert_equal(items[5].id,found[0].id)
    assert_equal(items[4].id,found[1].id)
    assert_equal(items[3].id,found[2].id)
    
  end
    def test_recent_video
      MediaItemTest.set_up
      items=[]
    (0..5).each do |i|
      item=Mediaitem.new
      item.created_time=Time.now+i*100
      item.HasVideo=true
      item.is_private=false
      assert(item.is_private==false)
      item.save
      items<<item
      
        item=Mediaitem.new
      item.created_time=Time.now+i*100
      item.HasAudio=true
      item.is_private=false
      item.save
      items<<item
      
      item=Mediaitem.new
      item.created_time=Time.now+i*100
      item.HasImage=true
      item.is_private=false
      item.save
      items<<item
    end
    
    found=Mediaitem.recent_video(3)
    assert_equal(3,found.length)
    assert_equal(items[15].id,found[0].id)
    assert_equal(items[12].id,found[1].id)
    assert_equal(items[9].id,found[2].id)
    
 found=Mediaitem.recent_audio(3)
    assert_equal(3,found.length)
    assert_equal(items[16].id,found[0].id)
    assert_equal(items[13].id,found[1].id)
    assert_equal(items[10].id,found[2].id)
    NotRelational::RepositoryFactory.instance.pause()
 found=Mediaitem.recent_images(3)
    assert_equal(3,found.length)
    assert_equal(items[17].id,found[0].id)
    assert_equal(items[14].id,found[1].id)
    assert_equal(items[11].id,found[2].id)
    
   end
       def test_mediafiles
       MediaItemTest.set_up
        item=Mediaitem.new
       item.save
       
       thumb_file=Mediafile.new
       thumb_file.mediaitem_id=item.id
       thumb_file.width=100
       thumb_file.height=80
       thumb_file.save
     
       big_file=Mediafile.new
       big_file.mediaitem_id=item.id
       big_file.width=1200
       big_file.height=1000
       big_file.save
       
          found=item.mediafiles
      
      assert_not_nil found
       assert_equal(2,found.length)
       end
   
    
    def test_thumbfile
       MediaItemTest.set_up
       item=Mediaitem.new
       item.save
       
       tiny_thumb_file=Mediafile.new
       tiny_thumb_file.mediaitem_id=item.id
       tiny_thumb_file.width=50
       tiny_thumb_file.height=60
       tiny_thumb_file.mimeType="image/gif"
       tiny_thumb_file.save
     
       thumb_file=Mediafile.new
       thumb_file.mediaitem_id=item.id
       thumb_file.width=120
       thumb_file.height=80
       thumb_file.mimeType="image/gif"
       thumb_file.save
     
       square_thumbfile=Mediafile.new
       square_thumbfile.mediaitem_id=item.id
       square_thumbfile.width=100
       square_thumbfile.height=100
       square_thumbfile.mimeType="image/png"
       square_thumbfile.save
     
        big_thumbfile=Mediafile.new
       big_thumbfile.mediaitem_id=item.id
       big_thumbfile.width=200
       big_thumbfile.height=200
       big_thumbfile.mimeType="image/png"
       big_thumbfile.save
     
       big_file=Mediafile.new
       big_file.mediaitem_id=item.id
       big_file.width=1200
       big_file.height=1000
       big_file.mimeType="image/jpeg"
       big_file.save
     
      big640_file=Mediafile.new
       big640_file.mediaitem_id=item.id
       big640_file.width=640
       big640_file.height=480
       big640_file.mimeType="image/jpeg"
       big640_file.save
     
      found=item.thumbfile      
      assert_not_nil found
      assert_equal(thumb_file.id,found.id)
      
       found=item.square_thumbfile   
      assert_not_nil found
      assert_equal(square_thumbfile.id,found.id)
      
      found=item.tiny_thumbfile      
      assert_not_nil found
      assert_equal(tiny_thumb_file.id,found.id)
     
      found=item.big_thumbfile      
      assert_not_nil found
      assert_equal(big_thumbfile.id,found.id)
      
      found=item.file640   
      assert_not_nil found
      assert_equal(big640_file.id,found.id)
       
      found=item.fileMaxSize      
      assert_not_nil found
      assert_equal(big_file.id,found.id)
      
      
      found=item.large_files      
      assert_not_nil found
      assert_equal(2,found.length)
    
      found=item.get_file_by_size_string('640x480')     
      assert_not_nil found
       assert_equal(big640_file.id,found.id)
     
      found=item.get_file_by_size_string('1200x1000')     
      assert_not_nil found
       assert_equal(big_file.id,found.id)
     
    end
   
   
   
    def test_get_tag_cloud
           MediaItemTest.set_up
   item=Mediaitem.new
    item.save
    
      tag=Tag.new
    tag.tag_name='duh'
    tag.mediaitem_id=item.id
    tag.save
     
      
       tag=Tag.new
    tag.tag_name='duh2'
    tag.mediaitem_id=item.id
    tag.save
    
        tag=Tag.new
    tag.tag_name='duh2'
    tag.mediaitem_id=item.id
    tag.save
    
      
    tag=Tag.new
    tag.tag_name='duhnot'
    tag.save
    
     found=item.get_tag_cloud
     assert_not_nil found
      assert_equal(2,found.length)
      assert_equal('duh2',found[0])
      assert_equal('duh',found[1])
     
    end
      
    def test_kill
        
    end
    def test_add_rating
        
    end

    def test_rating
        MediaItemTest.set_up
      item=Mediaitem.new
      item.save


      tag=Rating.new
      tag.rating=3
      tag.mediaitem_id=item.id
      tag.save

      tag=Rating.new
      tag.rating=4
      tag.mediaitem_id=item.id
      tag.save
     rating=item.rating
    assert_equal(3.5,rating)
     
    
    
    end

    def test_rated_by_user
       MediaItemTest.set_up
      item=Mediaitem.new
      item.save

      assert(!item.rated_by_user?('david'))

      tag=Rating.new
      tag.rating=3
      tag.user_name='david'
      tag.mediaitem_id=item.id
      tag.save
      NotRelational::RepositoryFactory.instance.pause(3)
      assert(item.rated_by_user?('david'))

    end
    def test_get_rating_by_user_name
         MediaItemTest.set_up
      item=Mediaitem.new
      item.save

     
      tag=Rating.new
      tag.rating=2
      tag.user_name='joe'
      tag.mediaitem_id=item.id
      tag.save
      
      tag1=Rating.new
      tag1.rating=3
      tag1.user_name='david'
      tag1.mediaitem_id=item.id
      tag1.save
      
      tag=Rating.new
      tag.rating=4
      tag.user_name='ed'
      tag.mediaitem_id=item.id
      tag.save
      
      found=item.get_rating_by_user_name('david')
      assert_equal(3,found)
    end
end
