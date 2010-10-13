
require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class ConsistentReadTest < Test::Unit::TestCase
  def ConsistentReadTest.set_up
    NotRelational::RepositoryFactory.instance.clear_session_cache
    UserEvent.find(:all).each do |x|
      x.destroy
      puts "destroyed #{x.login}"
    end
    NotRelational::RepositoryFactory.instance.clear_session_cache
  end

  def test_write_read
    ConsistentReadTest.set_up
    10.times do |i|
      u=UserEvent.new(
                      :login=> "login_#{i}",
                      :blurb => "blurb_#{i}")
      u.save!
    end
    NotRelational::RepositoryFactory.instance.clear_session_cache
    found=UserEvent.find(:all,:order_by => :login,:consistent_read => true)
    assert_equal(10,found.length)
    10.times do |i|
      assert_equal("login_#{i}",found[i].login)
      assert_equal("blurb_#{i}",found[i].blurb)
      found[i].blurb="aaa_blurb_#{i}"
      found[i].save
    end
    NotRelational::RepositoryFactory.instance.clear_session_cache
    
    found=UserEvent.find(:all,:order_by => :login,:consistent_read => true)
    assert_equal(10,found.length)
    10.times do |i|
      assert_equal("login_#{i}",found[i].login)
      assert_equal("aaa_blurb_#{i}",found[i].blurb)
      found[i].destroy
    end
    NotRelational::RepositoryFactory.instance.clear_session_cache
    
    found=UserEvent.find(:all,:order_by => :login,:consistent_read => true)
    
    assert_equal(0,found.length)

  end

end



