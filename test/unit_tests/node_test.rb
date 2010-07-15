require 'test/test_helper.rb'

class NodeTest < Test::Unit::TestCase
  
  def NodeTest.set_up
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
    NotRelational::RepositoryFactory.instance.clear
  end
  def test_content_persists
    
    node= Node.fill_new_node('david', "my title", 'hello world')
    node.save
    
    found=Node.find(node.id)
    assert_not_nil(found)
    assert(!found.is_dirty(:latestContent))
    assert_equal('hello world',found.latestContent)
    assert(!found.is_dirty(:latestContent))
    found.latestContent="goodbye"
    assert(found.is_dirty(:latestContent))
  end
  def test_select_by_clicks
    NodeTest.set_up
    (0..5).each do | i|
      node= Node.fill_new_node('david', "#{i}", 'hello world')
      node.clicks=i
      node.save
    end
    NotRelational::RepositoryFactory.instance.pause();
    found=Node.find(
                    :all,
                    :conditions=>{:clicks=>NotRelational::AttributeRange.new(:greater_than=>3)})
    assert_equal(2,found.length)
  end
  def test_recent
    NodeTest.set_up
    nodes=[]
    (0..5).each do | i|
      
      node= Node.fill_new_node('david', "#{i}", 'hello world')
      node.language_id='en'
      node.publicRead=true
      node.save
      
      nodes<<node
      
    end
    NotRelational::RepositoryFactory.instance.pause()
    
    recent=Node.recent('en',2)    
    assert_equal(2,recent.length)
    assert_equal(nodes[5].id,recent[0].id)
    assert_equal(nodes[4].id,recent[1].id)
    assert_equal('5',recent[0].latestTitle )
    assert_equal('4',recent[1].latestTitle )
  end
  def test_get_nearby_features
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.longitude=50
    node.latitude=-50
    node.address=node.location.to_address
    node.save
    node2= Node.fill_new_node('david', 'my new post', 'hello world')
    node2.longitude=51
    node2.latitude=-51
    node2.address=node2.location.to_address
    node2.save
    node2= Node.fill_new_node('david', 'my new post', 'hello world')
    node2.longitude=80
    node2.latitude=-80
    node2.address=node2.location.to_address
    node2.save
    NotRelational::RepositoryFactory.instance.pause()
    results=Node.find_near(NotRelational::Geo::Location.new(-51,51),4)
    assert_equal(2,results.length)
    
    results=Node.find_near(NotRelational::Geo::Location.new(-51,51),12)
    assert_equal(1,results.length)
    
    
  end
  
  
  
  def test_set_up
    NodeTest.set_up
  end
  def test_children
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    child=Node.fill_new_node('david2', 'my new post2', 'hello world2')
    child.parent_id=node.id
    child.save
    child2=Node.fill_new_node('david3', 'my new post3', 'hello world3')
    child2.parent_id=node.id
    child2.save
    not_child=Node.fill_new_node('n', 'n', 'n3')
    
    not_child.save
    NotRelational::RepositoryFactory.instance.pause()
    assert_equal(2,node.children.length)
  end
  
  
  def test_child_count
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    child=Node.fill_new_node('david2', 'my new post2', 'hello world2')
    child.parent_id=node.id
    child.save
    child2=Node.fill_new_node('david3', 'my new post3', 'hello world3')
    child2.parent_id=node.id
    child2.save
    not_child=Node.fill_new_node('n', 'n', 'n3')
    
    not_child.save
    NotRelational::RepositoryFactory.instance.pause()
    assert_equal(2,node.child_count)   
  end
  
  def test_parent
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    child=Node.fill_new_node('david2', 'my new post2', 'hello world2')
    child.parent_id=node.id
    child.save
    parent=child.parent
    assert(parent!=nil)
    assert_equal(parent.id,node.id)
    
  end 
  def test_author
    joe=User.find('joe')
    if joe
      joe.destroy
    end
    NodeTest.set_up
    
    user=User.new
    user.login='joe'
    user.save!
    
    node1= Node.fill_new_node('222', 'title222', 'content222')
    node1.save
    node= Node.fill_new_node('joe', 'title', 'content')
    node.save
    
    NotRelational::RepositoryFactory.instance.pause()
    
    
    author=node.author
    assert(author!=nil)
    assert_equal('joe',author.login)
    author_nodes=author.nodes
    assert(author_nodes!=nil)
    assert_equal(1,author_nodes.length)
    assert_equal('title',author_nodes[0].latestTitle)
    
  end
  
  
  def test_place
    NodeTest.set_up
    place=Place.new
    place.name='Paris'
    place.longitude=-10
    place.latitude=10
    place.address=place.location.to_address
    place.save!
    
    node1= Node.fill_new_node('222', 'title222', 'content222')
    node1.place_id=place.id
    node1.save
    
    found_place=node1.place
    assert(found_place!=nil)
    assert_equal(place.id,found_place.id)
    
  end
  
  
  def test_get_nearby_places
    NodeTest.set_up
    place=Place.new
    place.name='Paris'
    place.longitude=-10
    place.latitude=10
    place.address=place.location.to_address
    place.save!
    
    place=Place.new
    place.name='Paris'
    place.longitude=-11
    place.latitude=11
    place.address=place.location.to_address
    place.save!
    
    place=Place.new
    place.name='Paris'
    place.longitude=-50
    place.latitude=50
    place.address=place.location.to_address
    place.save!
    
    node1= Node.fill_new_node('222', 'title222', 'content222')
    
    node1.longitude=-10
    node1.latitude=10
    node1.address=node1.location.to_address
    node1.save
    
    NotRelational::RepositoryFactory.instance.pause()
    results=node1.get_nearby_places(4)
    assert_equal(2,results.length)
    
    results=node1.get_nearby_places(12)
    assert_equal(1,results.length)
  end
  
  def test_ancestor_place
    NodeTest.set_up
    place=Place.new
    place.name='Paris'
    place.save!
    place2=Place.new
    place2.name='London'
    place2.save!
    
    node1= Node.fill_new_node('222', 'title222', 'content222')
    node1.place_id=place.id
    node1.AncestorPlace=place2.id
    node1.save
    
    found_place=node1.ancestor_place
    assert(found_place!=nil)
    assert_equal(place2.id,found_place.id)
  end
  
  def test_Album
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    node_album=Album.new
    node_album.guid=node.album_guid
    node_album.user_name='david'
    node_album.save
    
    found=node.Album
    assert(found!=nil)
    assert_equal(node_album.id,found.id)
  end
  
  
  
  def test_mediaitems
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    node2= Node.fill_new_node('david2', 'my new post2', 'hello world2')
    node2.save
    
    node_album=Album.new
    node_album.guid=node.album_guid
    node_album.user_name='david'
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

    NotRelational::RepositoryFactory.instance.clear_session_cache

    found=node.mediaitems
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node2.mediaitems
    assert(found!=nil)         
    assert_equal(1,found.length)
    assert_equal(mediaitem3.id,found[0].id)
    
  end
  def test_duh
    NodeTest.set_up
    node= Node.fill_new_node('david', 'dogs', 'cats')
    node.publicRead=true
    node.isChannel=true
    node.save
    
    nodes << node
    
  end
  def test_segmented_media
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    
    node2= Node.fill_new_node('david2', 'my new post2', 'hello world2')
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
  def test_repeat_query
    NodeTest.set_up
    node_x= Node.fill_new_node('xxx', 'titlexxx', 'contentxxx')
    node_x.save
    NotRelational::RepositoryFactory.instance.pause();
    

    result=Node.find_by_username("xxx")
    assert_equal(1,result.size)
    result=Node.find_by_username("xxx")
    assert_equal(1,result.size)
    
  end

  #   def test_recent_public_for_user
  #     joe=User.find('joe')
  #     if joe
  #       joe.destroy
  #     end
  #     NodeTest.set_up
  
  #     user=User.new
  #     user.login='joe'
  #     user.save!
  
  def test_mediaitems
    NodeTest.set_up
    node= Node.fill_new_node('david', 'my new post', 'hello world')
    node.save
    node2= Node.fill_new_node('david2', 'my new post2', 'hello world2')
    node2.save
    
    node_album=Album.new
    node_album.guid=node.album_guid
    node_album.user_name='david'
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
    NotRelational::RepositoryFactory.instance.clear_session_cache
    found=node.mediaitems
    assert(found!=nil)         
    assert_equal(2,found.length)
    
    found=node2.mediaitems
    assert(found!=nil)         
    assert_equal(1,found.length)
    assert_equal(mediaitem3.id,found[0].id)
    
  end
  def test_duh
    NodeTest.set_up
    node= Node.fill_new_node('david', 'dogs', 'cats')
    node.publicRead=true
    node.isChannel=true
    node.save
    NotRelational::RepositoryFactory.instance.pause()
  end
end
