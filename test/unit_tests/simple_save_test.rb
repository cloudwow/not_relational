
require 'rubygems'
require 'test/unit'

$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../test')
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
