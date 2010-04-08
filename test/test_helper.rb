require 'rubygems'
require 'test/unit'
require 'shoulda'
ENV['NOT_RELATIONAL_ENV']='testing'



$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.push(File.dirname(__FILE__) +'/../../test/models')

$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__)+"/../lib/not_relational.rb"


class Test::Unit::TestCase
end

