require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class CollectionTest < Test::Unit::TestCase
  def set_up
    Mediaitem.find(:all).each do |node|
      node.destroy
    end
  end
  def test_collections
    items=[]
    (0..5).each do |i|
      item=Mediaitem.new
      item.created_time=Time.now+i*100
      metadata=[]
      (0..5).each do |j|
        metadata << "#{i} #{j}"
      end
      item.metadata=metadata
      item.save
      
      items << item
    end

    items.each do |item|
      found_item=Mediaitem.find(item.id)
      assert_not_nil(found_item)
      assert_not_nil(found_item.metadata)
      assert_equal(6,found_item.metadata.length)
      
    end
  end
end
