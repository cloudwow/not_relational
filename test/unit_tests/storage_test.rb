require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class StorageTest < Test::Unit::TestCase

  def test_put_small
    NotRelational::Repository.storage.put("alnitakTest","duh1","hello")
  end

end
