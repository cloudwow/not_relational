# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'

require File.dirname(__FILE__) +'/../../lib/not_relational/repository_factory.rb'
ENV['not_relational_ENV']='testing'

class RepositoryFactoryTest < Test::Unit::TestCase
  def test_foo
    found=NotRelational::RepositoryFactory.instance
    assert_not_nil found
  end
end
