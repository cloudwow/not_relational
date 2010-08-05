require "not_relational/starts_with_condition.rb"
module NotRelational

  module Locatable

    def self.included(target_class)
      target_class.extend(ClassMethods)
    end
    def location
      return NotRelational::Location.new(latitude,longitude)
    end
    def get_nearby(zoom_level=7,order=nil)
      if latitude==nil or longitude==nil 
        return []
      end
      result= self.class.find_near(self.location,zoom_level,order)
      result.delete_if{|item|item.id==id}
      return result
    end
    
    #mixin
    #locatable object must have latitude, longitude and address attributes
    module ClassMethods

      def find_near(loc,zoom_level=7,order_by=nil,order=:ascending)
        nearby= loc.get_nearby_addresses(zoom_level)

        address_params=[]
        for address in nearby
          
          address_params << StartsWithCondition.new(self.AttributeDescription(:address),address)
          
        end
        orCondition=OrCondition.new(address_params)
        
        return self.find(:all,:limit => 24,:order_by => order_by,:order => order,:conditions=>[orCondition])
        
      end
    end

  end
end
