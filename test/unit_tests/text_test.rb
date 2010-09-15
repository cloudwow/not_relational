require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class TextTest < Test::Unit::TestCase

  def test_long_text_then_nil

    t="0123456789"*200
    n=Node.new(:latestContent => t)
    n.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_not_equal(:in_storage,found.latestContent)
    assert_not_nil(found.latestContent)
    assert(t==found.latestContent)
    found.latestContent=nil
    found.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_nil(found.latestContent)
  end

  def test_short_text
    n=Node.new(:latestContent => "blah")
    n.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_equal("blah",found.latestContent)
    
  end


  def test_short_text_then_long
    n=Node.new(:latestContent => "blah")
    n.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_equal("blah",found.latestContent)

        t="0123456789"*200

    n.latestContent=t
    n.save
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause

        found=Node.find(n.id)
    assert_not_nil(found)
    assert_not_equal(:in_storage,found.latestContent)
    assert_not_nil(found.latestContent)
    assert(t==found.latestContent)

  end

  def test_long_text

    t="0123456789"*200
    n=Node.new(:latestContent => t)
    n.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_not_equal(:in_storage,found.latestContent)
    assert_not_nil(found.latestContent)
    assert(t==found.latestContent)
    
  end

  

  def test_long_text_then_short

    t="0123456789"*200
    n=Node.new(:latestContent => t)
    n.save!
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_not_equal(:in_storage,found.latestContent)
    assert_not_nil(found.latestContent)
    assert(t==found.latestContent)
    found.latestContent="wtf"
    found.save!

    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=Node.find(n.id)
    assert_not_nil(found)
    assert_equal("wtf",found.latestContent)
  end
end
