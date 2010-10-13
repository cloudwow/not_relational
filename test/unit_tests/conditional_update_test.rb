require File.expand_path(File.dirname(__FILE__)) + '/../test_helper.rb'
require "openssl"


module NotRelational

  class ConditionalUpdateTest < Test::Unit::TestCase


    def test_update_when_date_nil
      n=Node.new(
                 :latestTitle => "title_1",
                 :latestContent => "content_1",
                 :creationTime => nil)

      n.save!

      NotRelational::Repository.clear_session_cache
      NotRelational::Repository.pause
      n2=Node.find(n.id)
      n2.latestTitle="duh"
      n2.creationTime = Time.now.gmtime
      n2.save(:expected => {:creationTime => nil})
      
      NotRelational::Repository.clear_session_cache
      NotRelational::Repository.pause
      
      n3=Node.find(n.id,:consistent_read => true)
      assert_equal('duh',n3.latestTitle)
      assert_not_nil(n3.creationTime)
      assert_raise(ConsistencyError) do
        n3.save(:expected => {:creationTime => nil})
      end
      
    end

  end
end
