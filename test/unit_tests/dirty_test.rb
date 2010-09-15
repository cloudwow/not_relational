require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class DirtyTest < Test::Unit::TestCase

  def test_dirty_on_off

    target=Node.new

    assert(!target.is_dirty(:latestContent))
    assert(!target.is_dirty(:latestTitle))
    target.title="my title"
    assert(!target.is_dirty(:latestContent))
    assert(target.is_dirty(:latestTitle))
    target.content="my content"
    assert(target.is_dirty(:latestContent))
    assert(target.is_dirty(:latestTitle))

    target.save!

    assert(!target.is_dirty(:latestContent))
    assert(!target.is_dirty(:latestTitle))

    found=Node.find(target.id)

    assert_not_nil(found)
    assert(!found.is_dirty(:latestContent))
    assert_equal('my content',found.latestContent)
    assert(!found.is_dirty(:latestContent))
    found.latestContent="goodbye"
    assert(found.is_dirty(:latestContent))

  end
  
end
