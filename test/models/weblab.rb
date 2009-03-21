require 'digest/sha1'
require "uri"

require "model/domain_model.rb"


class Weblab < DomainModel
  property :id,:string,:is_primary_key=>true
 property :name,:string
 property :is_active ,:boolean                             
 property :adsense_channel,:string
 property :score,:integer
 property :layout,:text
 property :stylesheet,:text
 property :created_date,:date

end
