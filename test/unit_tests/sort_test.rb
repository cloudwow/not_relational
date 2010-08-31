require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class SortTest < Test::Unit::TestCase
  def SortTest.set_up
    CompositeKeyThing2.find(:all).each do |node|

      node.destroy
    end

  end
  def test_float_sort
    SortTest.set_up
    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache


    things=[]
    5.times do |i|
      thing=CompositeKeyThing2.new
      thing.site_id="yahoo"
      thing.product_id="prod_id_#{i}"
      thing.stuff="stuff_#{i}"

      thing.save
      things << thing
    end
    things[2].social_score=1.00000001
    things[1].social_score=1.0004001
    things[0].social_score=1.020001
    things[4].social_score=1.00001
    things[3].social_score=1.1001

    things.each{|x|x.save!}
    NotRelational::RepositoryFactory.instance.pause
    NotRelational::RepositoryFactory.instance.clear_session_cache

    result=CompositeKeyThing2.find(:all,
                            :params => {:site_id => "yahoo"},
                            :limit => 20,
                            :order_by => :social_score,
                                   :order => :descending)

    assert_equal(5,result.length)
    assert_equal("stuff_3",result[0].stuff)
    assert_equal("stuff_0",result[1].stuff)
    assert_equal("stuff_1",result[2].stuff)
    assert_equal("stuff_4",result[3].stuff)
  end
end
