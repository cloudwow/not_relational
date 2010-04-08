require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
class CompositeKeyThing < NotRelational::DomainModel
  
  property :name,:string,:is_primary_key=>true
  property :is_good,:bool,:is_primary_key=>true
  property :the_time , :date,:is_primary_key=>true
end
