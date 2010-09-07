require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class EnumTest < Test::Unit::TestCase
  def self.set_up
  end

  def test_foo
    title="<>.?:; one & two"
    content= "three & four"
    c=Comment.new(:title => title ,:content => content)
    c.save!
    NotRelational::Repository.pause
    NotRelational::Repository.clear_session_cache

    found=Comment.find(:all,:params => {:id => c.id })
    assert_equal(1,found.length)
    assert_equal(title,found[0].title)
    assert_equal(content,found[0].content)

    NotRelational::Repository.clear_session_cache
    
    found=Comment.find(c.id)
    assert_not_nil(found)
    assert_equal(title,found.title)
    assert_equal(content,found.content)
  end
end
