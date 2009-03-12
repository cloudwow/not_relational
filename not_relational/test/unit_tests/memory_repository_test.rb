# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')

require File.dirname(__FILE__) +'/../../lib/not_relational/memory_repository.rb'
require File.dirname(__FILE__) +'/../../test/models/node.rb'
ENV['not_relational_ENV']='testing'

class MemoryRepositoryTest < Test::Unit::TestCase

# 500=2.64 seconds
# 500=2.9 sav index seconds
# 1.7
  def test_foo
    return
    #repo=NotRelational::MemoryRepository.new
    (0..500).each do |i|
      node= Node.fill_new_node('david', "test node #{i}", 'hello world {i}')
      node.publicRead= ((i%30)==0)
      node.isChannel=((i%20)==0)

      node.save

    end
    (0..500).each do |i|
      found= Node.find_by_public_channel(true,true)
  assert_equal(9,found.length)

    end

       NotRelational::RepositoryFactory.instance.clear
  end

#  def test_foo2
#    #repo=NotRelational::MemoryRepository.new
#    nodes=[]
#    (0..100).each do |i|
#      node= Node.fill_new_node('david', "test node #{i}", 'hello world {i}')
#      node.publicRead= ((i%3)==0)
#      node.isChannel=((i%2)==0)
#
#      node.save
#      nodes<<node
#    end
#
#    nodes.each do |n|
#
#      found= Node.find(n.id)
#      index_found=Node.find_by_public_channel(n.publicRead,n.isChannel)
#
#      assert_not_nil(found)
#      found.destroy
#      found= Node.find(n.id)
#      assert_nil(found)
#      index_found_after=Node.find_by_public_channel(n.publicRead,n.isChannel)
#      assert_equal(index_found.length-1,index_found_after.length)
#    end
#
#
#
#
#       NotRelational::RepositoryFactory.instance.clear
#  end

end
