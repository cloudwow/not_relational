# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'

$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')

require File.dirname(__FILE__) +'/../../test/models/page_view_summary.rb'
require File.dirname(__FILE__) +'/../../test/models/page_view_detail.rb'
ENV['NOT_RELATIONAL_ENV']='testing'
class CompositeKeyTest < Test::Unit::TestCase
  def CompositeKeyTest.set_up

    PageViewSummary.find(:all).each do |node|
      puts node.inspect
        node.destroy
    end
    PageViewDetail.find(:all).each do |node|

      node.destroy
    end
    
  end

  def test_delete_null_key_part
    CompositeKeyTest.set_up
    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache


     all=PageViewSummary.find(:all)
    assert_equal(0,all.length)

     x=PageViewSummary.new(:username=>'david',:date=>nil,:page_view_count=>7)
    x.save!

    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache

    all=PageViewSummary.find(:all)
    assert_equal(1,all.length)
    all[0].destroy

    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache
 
    all=PageViewSummary.find(:all)
    assert_equal(0,all.length)

  end
  
  def test_foo
    CompositeKeyTest.set_up
    NotRelational::RepositoryFactory.instance.pause
    date=Time.gm(2008,12,25)
    x=PageViewSummary.new(:username=>'david',:date=>nil,:page_view_count=>7)
    y=PageViewSummary.new(:username=>'joe',:date=>date,:page_view_count=>6)
    z=PageViewSummary.new(:username=>'david',:date=>date+500,:page_view_count=>5)
    x.save
    y.save
    z.save
    found_x=PageViewSummary.find(['david',nil])
    assert_not_nil(found_x)
    found=PageViewSummary.find(['david',date+500])
    assert_not_nil(found)
    assert_equal(5, found.page_view_count)

    a=PageViewDetail.new(:username=>'david',:date=>nil,:url=>'url1',  :page_view_count=>1)
    a.save
    b=PageViewDetail.new(:username=>'david',:date=>nil,:url=>'url2',  :page_view_count=>3)
    assert_equal(7, found_x.page_view_count)

    found=PageViewSummary.find(['joe',date])
    assert_not_nil(found)
    assert_equal(6, found.page_view_count)

    b.save
    c=x.create_child_pageviewdetail(:url=>'url3',  :page_view_count=>5)
    c.save

    d=y.create_child_pageviewdetail(:url=>'url_y',  :page_view_count=>77)
    d.save
    
    x_details=found_x.page_view_details

    assert_equal(3,x_details.length)
    y_details=y.page_view_details

    assert_equal(1,y_details.length)
    assert_equal(77,y_details[0].page_view_count)
    assert_equal('url_y',y_details[0].url)

    found_x_2=c.page_view_summary
    assert_not_nil(found_x_2)
    assert_equal(7, found_x_2.page_view_count)

    found_y_2=d.page_view_summary
    assert_not_nil(found_y_2)
    assert_equal(6, found_y_2.page_view_count)


  end
end
