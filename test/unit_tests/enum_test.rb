# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'

$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')

require File.dirname(__FILE__) +'/../../test/models/page_view_summary.rb'
require File.dirname(__FILE__) +'/../../test/models/page_view_detail.rb'
ENV['NOT_RELATIONAL_ENV']='testing'
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

    y=PageViewSummary.new(:username=>'joe',:date=>date,:page_view_count=>6, :type=>PageViewSummary::Type::BLOG)
    assert(y.is_type_blog?)

  end
end
