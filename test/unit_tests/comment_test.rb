require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'

class CommentTest < Test::Unit::TestCase
  def CommentTest.set_up
    
    Mediaitem.find(:all).each do |node|
      node.destroy
    end
    User.find(:all).each do |node|
      node.destroy
    end
     Comment.find(:all).each do |node|
      node.destroy
    end
       
  end
   def test_recent
      
    end
    def test_recent_by_user
      
    end
end
