require 'digest/sha1'
require "uri"

require "model/domain_model.rb"


class Language < DomainModel
  property :id,:string,:is_primary_key=>true
 property :name,:string
 property :enabled ,:boolean  
 
    def Language.enabled_languages
     Language.find(:all,:order_by => 'name',:params=>{:enabled=>true}) 
     
    end
end
