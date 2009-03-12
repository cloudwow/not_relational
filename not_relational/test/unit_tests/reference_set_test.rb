# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'

$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')

require File.dirname(__FILE__) +'/../../test/models/page_view_summary.rb'
require File.dirname(__FILE__) +'/../../test/models/page_view_detail.rb'
require File.dirname(__FILE__) +'/../../test/models/node.rb'
ENV['not_relational_ENV']='testing'
class ReferenceSetTest < Test::Unit::TestCase
  def ReferenceSetTest.set_up

    PageViewSummary.find(:all).each do |node|
      node.destroy
    end
        Node.find(:all).each do |node|
      node.destroy
    end

  end
  def test_foo
    ReferenceSetTest.set_up
    return
    NotRelational::RepositoryFactory.instance.pause
    date=Time.gm(2008,12,25)
    x=PageViewSummary.new(:username=>'david',:date=>date,:page_view_count=>7)
    y=PageViewSummary.new(:username=>'joe',:date=>date,:page_view_count=>6)
    z=PageViewSummary.new(:username=>'david',:date=>date+500,:page_view_count=>5)
    x.save
    y.save
    z.save

       node= Node.fill_new_node('david', "my title", 'hello world')
    node.save

    x.add_to_details(node)
    x.save

    found_x=PageViewSummary.find(x.primary_key)
    assert_equal(1,found_x.details.length)
    assert_equal('my title',found_x.details[0].latestTitle)
    assert_equal(node.id,found_x.details[0].id)

        node2= Node.fill_new_node('david2', "my title2", 'hello world')
    node2.save

    found_x.add_to_details(node2)
    found_x.save

    found_x2=PageViewSummary.find(x.primary_key)
    assert_equal(2,found_x2.details.length)
    assert_equal('my title',found_x.details[0].latestTitle)
    assert_equal(node.id,found_x.details[0].id)
assert_equal('my title2',found_x.details[1].latestTitle)
    assert_equal(node2.id,found_x.details[1].id)


    found_y=PageViewSummary.find(y.primary_key)
    assert_equal(0,found_y.details.length)

  end
end
