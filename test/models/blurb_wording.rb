require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"

class BlurbWording < NotRelational::DomainModel
  property :blurb_name,:string,:is_primary_key=>true
  property :blurb_namespace,:string,:is_primary_key=>true
  property :language_id , :string  ,:is_primary_key=>true
  property :text,:text
  property :title , :string  
  property :version , :string  
  property :author , :string  
  property :time_utc , :date
  
  belongs_to :Blurb,:blurb_name
  
end