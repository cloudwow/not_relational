require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class EnumTest < Test::Unit::TestCase
  def self.set_up

    PageViewSummary.find(:all).each do |node|
      node.destroy
    end
    PageViewDetail.find(:all).each do |node|
      node.destroy
    end
    
  end
  def test_foo
    self.class.set_up
    date=Time.gm(2008,12,25)

    y=PageViewSummary.new(:username=>'joe',:date=>date,:page_view_count=>6, :type=>:BLOG)
    assert(y.is_type_blog?)

  end
  def test_bad_enum_throws
    assert_raise RuntimeError do
      PageViewSummary.new(:username=>'joe',:date=>Time.now,:page_view_count=>6, :type=>:BLAH)

    end
    x=PageViewSummary.new(:username=>'joe',:date=>Time.now,:page_view_count=>6, :type=>:BLOG)

    assert_raise RuntimeError do
      x.type=:sdfsdf
    end
  end
  def test_find_all
    self.class.set_up
    #test finding a collection of items with an enum in them+
    x1=PageViewSummary.new(
                           :username => "x1",
                           :date => Time.now,
                           :type => :BLOG)

    x1.save

    x2=PageViewSummary.new(
                           :username => "x2",
                           :date => Time.now,
                           :type => :HOMEPAGE)

    x2.save

    NotRelational::RepositoryFactory.instance.pause()
    NotRelational::RepositoryFactory.instance.clear_session_cache

    found_x1=PageViewSummary.find(x1.primary_key)
    assert_not_nil(found_x1)

    assert_equal(:BLOG,found_x1.type)

    
    found=PageViewSummary.find(:all,:order_by => :username)
    assert_equal(2,found.length)
    assert_equal(:BLOG,found[0].type)
    assert_equal(:HOMEPAGE,found[1].type)

  end
end
