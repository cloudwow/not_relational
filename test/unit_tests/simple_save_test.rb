require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class SimpleSaveTest < Test::Unit::TestCase

  def test_simple
      
    a=Mediaitem.new
    a.guid='guid1'
    a.HasVideo=true
    a.save

    f=Mediaitem.find(a.id)
    assert_not_nil(f)
    assert_equal('guid1',f.guid)
    assert(f.HasVideo)

    node_album=Album.new
    node_album.user_name='david'
    node_album.save
    
    node_album.connect_mediaitem(a)
    NotRelational::RepositoryFactory.instance.pause()

    found_items=node_album.mediaitems
    assert_equal(1,found_items.length)

    f2=found_items[0]
    assert_equal('guid1',f2.guid)
    assert(f2.HasVideo)

  end
end
