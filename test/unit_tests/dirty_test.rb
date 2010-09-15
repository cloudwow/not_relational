require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class DirtyTest < Test::Unit::TestCase

  def test_dirty_collection
    target=Mediaitem.new
    assert(!target.is_dirty(:metadata))
    target.metadata << "blah"
    assert(target.is_dirty(:metadata))
    
  end

  def test_dirty_on_off

    target=Node.new(:publicRead => true)

    assert(target.is_dirty(:publicRead))
    assert(!target.is_dirty(:latestContent))
    assert(!target.is_dirty(:latestTitle))
    target.latestTitle="my title"
    assert(target.is_dirty(:publicRead))
    assert(!target.is_dirty(:latestContent))
    assert(target.is_dirty(:latestTitle))
    target.latestContent="my content"
    assert(target.is_dirty(:publicRead))
    assert(target.is_dirty(:latestContent))
    assert(target.is_dirty(:latestTitle))

    target.save!

    assert(!target.is_dirty(:publicRead))
    assert(!target.is_dirty(:latestContent))
    assert(!target.is_dirty(:latestTitle))

    found=Node.find(target.id)

    assert_not_nil(found)
    assert(!found.is_dirty(:publicRead))
    assert(!found.is_dirty(:latestContent))
    assert_equal('my content',found.latestContent)
    assert(!found.is_dirty(:latestContent))
    found.latestContent="goodbye"
    assert(found.is_dirty(:latestContent))

  end
  
end
