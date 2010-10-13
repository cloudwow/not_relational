
require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class NilTest < Test::Unit::TestCase
  def test_overwrite_prop_with_nil
    target=Comment.new
    target.title="my title"
    target.content="my content"
    target.save!

    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    
    found=Comment.find(target.id,:consistent_read=>true)
    assert_not_nil(found)
    assert_equal("my title",found.title)
    assert_equal("my content",found.content)
    found.title=nil
    found.content=nil
    found.save!

    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause

    found=Comment.find(target.id,:consistent_read=>true)
    assert_not_nil(found)
    assert_nil(found.title)
    assert_nil(found.content)

  end
end
