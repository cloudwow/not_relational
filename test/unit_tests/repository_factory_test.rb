require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class RepositoryFactoryTest < Test::Unit::TestCase
  def test_foo
    found=NotRelational::RepositoryFactory.instance
    assert_not_nil found
  end
end
