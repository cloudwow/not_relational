require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
#for testing composite keys
class PageViewSummary < NotRelational::DomainModel

  property :username,:string,:is_primary_key=>true
  property :date,:date,:is_primary_key=>true
  property :page_view_count,:integer
  property :details,:reference_set
  property :type,:integer,:enum =>[:BLOG,:HOMEPAGE,:PORTAL]
  has_many :PageViewDetail,:without_prefix

end
