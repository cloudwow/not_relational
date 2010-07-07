require 'rubygems'
require 'test/unit'
require 'shoulda'
ENV['NOT_RELATIONAL_ENV']='testing'


$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__)+"/../lib/not_relational.rb"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

$:.push(File.dirname(__FILE__) +'/../test/models')

require File.dirname(__FILE__) +'/../test/models/node.rb'
require File.dirname(__FILE__) +'/../test/models/user.rb'
require File.dirname(__FILE__) +'/../test/models/user_event.rb'
require File.dirname(__FILE__) +'/../test/models/place.rb'
require File.dirname(__FILE__) +'/../test/models/album.rb'
require File.dirname(__FILE__) +'/../test/models/media_item.rb'
require File.dirname(__FILE__) +'/../test/models/media_file.rb'
require File.dirname(__FILE__) +'/../test/models/tag.rb'
require File.dirname(__FILE__) +'/../test/models/rating.rb'
require File.dirname(__FILE__) +'/../test/models/comment.rb'
require File.dirname(__FILE__) +'/../test/models/page_view_detail.rb'


class Test::Unit::TestCase
end

