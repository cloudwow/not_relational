module NotRelational
  class Location
    

    attr_accessor :latitude
    attr_accessor :longitude
    
    def initialize(lat,lon)
      self.latitude=lat
      self.longitude=lon
    end

    def to_address
      if latitude==nil || longitude==nil
        return nil
      end      
      address='t'
      right=0
      top=0
      width=180.0
      height=90.0
      16.times do

        if latitude>top
          top=top+height/2.0
          if longitude<right
            right=right-width/2.0
            address<< 'q'
          else
            right=right+width/2.0
            address << 'r'
          end
        else

          top=top-height/2.0
          if longitude<right
            right=right-width/2.0
            address<< 't'
          else
            right=right+width/2.0
            address << 's'
          end
        end
        width=width/2.0
        height=height/2.0
        #    puts "#{address} w=#{width}  h=#{height} r=#{right}  t=#{top}"
      end
      return address
    end
    def get_nearby_addresses(zoom_level)
      address=self.to_address
      if address.length>(zoom_level+1)
        address=address.slice(0,zoom_level+1)        
      end
      
      result=[address]
      
      tileWidth=360.0/(2**zoom_level)
      tileHeight=180.0/(2**zoom_level)

      other=Location.new(self.latitude+tileHeight,self.longitude+tileWidth)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude+tileHeight,self.longitude)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude+tileHeight,self.longitude-tileWidth)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude-tileHeight,self.longitude+tileWidth)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude-tileHeight,self.longitude)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude-tileHeight,self.longitude-tileWidth)
      result << other.to_address.slice(0,zoom_level+1)


      other=Location.new(self.latitude,self.longitude+tileWidth)
      result << other.to_address.slice(0,zoom_level+1)

      other=Location.new(self.latitude,self.longitude-tileWidth)
      result << other.to_address.slice(0,zoom_level+1)


    end
    def  Location.to_location(address)
      width=90.0
      height=45.0

      index=0
      x=0
      y=0
      length=address.length-1
      length.times do
        index+=1

        puts address[index].chr
        case address[index].chr

        when 'r'
          x+=width
          y+=height
        when 'q'
          x-=width
          y+=height

        when 't'
          x-=width
          y-=height
        when 's'
          x+=width
          y-=height
        end
        width/=2
        height/=2
      end
      loc=Location.new
      loc.latitude=y
      loc.longitude=x
      return loc
    end

    def self.deg2rad(deg)
      (deg * Math::PI / 180)
    end
    
    def self.rad2deg(rad)
      (rad * 180 / Math::PI)
    end
    
    def self.acos(rad)
      Math.atan2(Math.sqrt(1 - rad**2), rad)
    end
    
    def distance_in_miles( loc2)
      lat2 = loc2.latitude
      lon2 = loc2.longitude
      theta = self.longitude - lon2
      
      dist = Math.sin(self.deg2rad(self.latitude)) * Math.sin(deg2rad(lat2)) + Math.cos(self.deg2rad(self.latitude)) * Math.cos(self.deg2rad(lat2)) * Math.cos(deg2rad(theta))
      
      dist = self.rad2deg(self.acos(dist))
      
      (dist * 60 * 1.1515).round #distance in miles
    end
    
  end
end
