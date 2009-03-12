# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'
$:.push(File.dirname(__FILE__) +'/../../test/models')
$:.push(File.dirname(__FILE__) +'/../../lib/not_relational')

require File.dirname(__FILE__) +'/../../lib/not_relational/memcache_repository.rb'
require File.dirname(__FILE__) +'/../../test/models/node.rb'

class MemcacheRepositoryTest < Test::Unit::TestCase

  def test_foo
#    NotRelational::RepositoryFactory.clear
#    ENV['not_relational_ENV']='memcache_s3_testing'
#    begin
#    nodes=[]
#    #500 nodes: with s3 =138 secs without s3 99 secs
#    (0..50).each do |i|
#      node= Node.fill_new_node('david', "test node #{i}", 'hello world {i}')
#      node.publicRead= ((i%30)==0)
#      node.isChannel=((i%20)==0)
#
#      node.save
#      nodes<<node
#    end
#    nodes.each do |n|
#      found= Node.find(n.id)
#      assert_not_nil(found)
#      assert_equal(n.id,found.id)
#    end
#    ensure
#NotRelational::RepositoryFactory.clear
#    ENV['not_relational_ENV']='testing'
#    end


  end
end
