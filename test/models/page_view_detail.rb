
require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
#for testing composite keys
class PageViewDetail < NotRelational::DomainModel

    property :username,:string,:is_primary_key=>true
  property :date,:date,:is_primary_key=>true
  property :url,:string,:is_primary_key=>true
   property :page_view_count,:integer
   belongs_to :PageViewSummary,:without_prefix

end
