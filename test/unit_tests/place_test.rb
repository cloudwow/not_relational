require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class PlaceTest < Test::Unit::TestCase
  def PlaceTest.set_up
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
    User.find(:all).each do |node|
      node.destroy
    end
    
  end
  def test_get_nearby_features()
    PlaceTest.set_up
    place= Place.new
    place.longitude=50
    place.latitude=-50
    place.address=place.location.to_address
    place.save
    place2= Place.new
    place2.longitude=51
    place2.latitude=-51
    place2.address=place2.location.to_address
    place2.save
    place2= Place.new
    place2.longitude=80
    place2.latitude=-80
    place2.address=place2.location.to_address
    place2.save
    results=Place.find_near(NotRelational::Location.new(-51,51),4)
    assert_equal(2,results.length)
    
    results=Place.find_near(NotRelational::Location.new(-51,51),12)
    assert_equal(1,results.length)
    
  end
  # def test_get_nearby_nodes()
  #   PlaceTest.set_up
  
  #    node=Node.fill_new_node('222', 'title222', 'content222')
  #       node.longitude=-10
  #       node.latitude=10
  #       node.address=node.location.to_address
  #       node.save!
  
  #       node=Node.fill_new_node('222', 'title222', 'content222')
  #       node.='Paris'
  #       node.longitude=-11
  #       node.latitude=11
  #       node.address=node.location.to_address
  #       node.save!
  
  #       node=Node.fill_new_node('222', 'title222', 'content222')
  #       node.name='Paris'
  #       node.longitude=-50
  #       node.latitude=50
  #       node.address=node.location.to_address
  #       node.save!
  
  #       place= Place.new
  
  #       place.longitude=-10
  #       place.latitude=10
  #       place.address=node1.location.to_address
  #       place.save
  
  
  #       results=place.get_nearby_nodes(4)
  #       assert_equal(2,results.length)
  
  #       results=node1.get_nearby_places(12)
  #       assert_equal(1,results.length)
  # end
  
  def test_Album
    PlaceTest.set_up
    node= Place.new
    node.save
    node_album=Album.new
    node_album.guid=node.album_guid
    node_album.save
    NotRelational::RepositoryFactory.instance.pause()

    found=node.Album
    assert(found!=nil)
    assert_equal(node_album.id,found.id)
  end
  def test_mediaitems
    PlaceTest.set_up
    
    node= Place.new
    node.save
    node2= Place.new
    node2.save
    
    node_album=Album.new
    node_album.guid=node.album_guid
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
    
    found=node.mediaitems
    assert(found!=nil)
    
    assert_equal(1,found.length)
    assert_equal(mediaitem1.id,found[0].id)
    
    node_album2=Album.new
    node_album2.guid=node2.album_guid
    node_album2.user_name='david2'
    node_album2.save
    
    node_album.connect_mediaitem(mediaitem2)
    node_album2.connect_mediaitem(mediaitem3)
    NotRelational::RepositoryFactory.instance.pause()
    NotRelational::RepositoryFactory.instance.clear_session_cache()
    found=node.mediaitems
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node2.mediaitems
    assert(found!=nil)         
    assert_equal(1,found.length)
    assert_equal(mediaitem3.id,found[0].id)
  end
  
  def test_segmented_media
    PlaceTest.set_up
    node= Place.new
    node.save
    
    node2= Place.new
    node2.save
    
    node_album=Album.new
    node_album.guid=node.album_guid
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
    
    found=node.video_media
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node.still_image_media
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node.audio_media
    assert(found!=nil)         
    assert_equal(1,found.length)
  end
end
