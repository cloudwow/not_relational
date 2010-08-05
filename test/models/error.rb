require 'digest/sha1'
require "uri"

require "model/domain_model.rb"


class Error < DomainModel
  property :id,:string,:is_primary_key=>true
  property :server,:string
  property :message ,:string
  property :stack_trace ,:string
  property :time_utc ,:date 
  
end
