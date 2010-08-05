require 'rubygems'
require 'test/unit'

ENV['NOT_RELATIONAL_ENV']='testing'




require File.expand_path(File.dirname(__FILE__)) +"/../lib/not_relational.rb"

$LOAD_PATH.unshift(File.join(File.expand_path(File.dirname(__FILE__)) , '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.expand_path(File.dirname(__FILE__)) , '..', 'lib/not_relational'))

$:.push(File.expand_path(File.dirname(__FILE__))  +'/../test/models')

require File.expand_path(File.dirname(__FILE__))  +'/../test/models/node.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/blurb.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/blurb_wording.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/user.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/user_event.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/place.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/album.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/media_item.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/media_file.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/tag.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/rating.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/comment.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/page_view_detail.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/page_view_summary.rb'
require File.expand_path(File.dirname(__FILE__))  +'/../test/models/composite_key_thing.rb'


class Test::Unit::TestCase
end

