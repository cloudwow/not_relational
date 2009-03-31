
require 'rubygems'
require 'test/unit'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')
require File.dirname(__FILE__) +'/../../lib/not_relational/domain_model.rb'
require File.dirname(__FILE__) +'/../../lib/not_relational/attribute_range.rb'

require File.dirname(__FILE__) +'/../../lib/not_relational/memory_repository.rb'
require File.dirname(__FILE__) +'/../../test/models/node.rb'
require File.dirname(__FILE__) +'/../../test/models/user.rb'
require File.dirname(__FILE__) +'/../../test/models/place.rb'
require File.dirname(__FILE__) +'/../../test/models/album.rb'
require File.dirname(__FILE__) +'/../../test/models/media_item.rb'
require File.dirname(__FILE__) +'/../../test/models/media_file.rb'
require File.dirname(__FILE__) +'/../../test/models/tag.rb'
require File.dirname(__FILE__) +'/../../test/models/rating.rb'
require File.dirname(__FILE__) +'/../../test/models/comment.rb'
require File.dirname(__FILE__) +'/../../test/models/blurb.rb'

ENV['NOT_RELATIONAL_ENV']='testing'

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
         metadata<<"#{i} #{j}"
      end
      item.metadata=metadata
      item.save
      
      items<<item
    end

     items.each do |item|
       found_item=Mediaitem.find(item.id)
       assert_not_nil(found_item)
       assert_not_nil(found_item.metadata)
       assert_equal(6,found_item.metadata.length)
      
     end
   end
 end