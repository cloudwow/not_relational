
require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class CountTest < Test::Unit::TestCase
  def CountTest.set_up
    Node.find(:all).each do |node|
      node.destroy
    end
    NotRelational::RepositoryFactory.instance.clear_session_cache

  end

  def test_count_some
    CountTest.set_up
    n=nil
    10.times do |i|
      n=Node.new
      n.latitude=i.to_f
      n.save
    end
    NotRelational::Repository.pause
    actual = Node.count
    assert_equal(10,actual)
    actual = Node.count(:latitude => 5.0)
    assert_equal(1,actual)

    #make sure it works when possibly cached
    actual = Node.count
    assert_equal(10,actual)
    actual = Node.count(:latitude => 5.0)
    assert_equal(1,actual)

    #dirty the cache
    n.destroy
    
    NotRelational::Repository.pause
    actual = Node.count
    assert_equal(9,actual)


  end
  def test_count_none
    CountTest.set_up
    NotRelational::Repository.pause
    actual = Node.count
    assert_equal(0,actual)

  end

end
