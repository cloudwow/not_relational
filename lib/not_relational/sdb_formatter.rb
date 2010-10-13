# encoding: utf-8

module NotRelational
  

  module SdbFormatter
    TEXT_IN_STORAGE= "storage:"
    TEXT_IS_NIL=     "nil    :"
    TEXT_IS_HERE=    "here   :"
    
    def parse_date(value)
      return nil if value==nil 
      if value.is_a? Date
        return value
      end
      if value.is_a? Time
        return value
      end
      return nil if value.length==0
      return Time.at(value.to_f).gmtime
    end

    def parse_boolean(value)
      return nil if value==nil 
      if value=="true"
        return true
      else
        return  false
      end
    end
    def parse_integer(value)
      return nil if value==nil 
      return value.to_i
      
    end
    def parse_enum(value)
      return nil if value==nil || value.empty?
      return value.to_sym
      
    end
    def parse_float(value)
      return nil if value==nil
      return value.to_f
    end

    def parse_property_bag(value)
      return {} if value==nil
      return YAML::load(value)

    end

    def parse_unsigned_integer(value)
      return nil if value==nil 
      return value.to_i
    end
    def parse_text(value)

      value.force_encoding "UTF-8"  if value
      if value && value.length>=TEXT_IS_HERE.length
        prefix=value[0..TEXT_IS_HERE.length-1]
        
        case prefix
        when TEXT_IS_HERE
          return value[TEXT_IS_HERE.length..-1]
        when TEXT_IN_STORAGE
          return :in_storage
        when TEXT_IS_NIL
          return nil
        end
      end
      if value
        #has value but does not match any prefix
        #this was a string

        return value
      else

        #backwards compatible from before anything for text was put in SDB
        return :in_storage
      end
    end
    def format_date(value)
      return nil if value==nil 
      return format("%.4f",value.to_f)
    end
    def format_boolean(value)
      
      return ((value == true) || (value==1)) ? 'true' : 'false'
    end
    def format_integer(value)
      
      
      if value==nil 
        return nil
      end
      return zero_pad_integer(value)
      #          return nil if value==nil 
      #       sign='p'
      #        if value<0
      #          sign='n'
      #        end
      #        return sign+zero_pad_integer(Math.abs(value))
      
    end
    def format_string(value)
      if value==nil 
        return nil
      end
      
      if value.length>1024
        value=value[0..1023]
      end
      value
    end
    def format_text(value)
      #text value should always have a prefix describing where the value is stored or if it is nil
      if value==nil 
        return TEXT_IS_NIL
      end
      
      if value.length>500
        return TEXT_IN_STORAGE
      end
      TEXT_IS_HERE+  value
    end
    def format_float(value)
      if value==nil 
        return nil
      end
      return zero_pad_float(value)
    end
    def format_enum(value)
      if value==nil 
        return nil
      end
      return value.to_s
    end
    def format_unsigned_integer(value)
      if !value
        return nil
      end
      return zero_pad_integer(value)
    end

    def format_property_bag(value)
      if !value
        return nil
      end
      return value.to_yaml#(:syck_compatible => true)
    end


    
    def zero_pad_integer(value)
      value=value.to_i
      temp= value.abs.to_s.rjust(30,"0")
      if value>=0
        temp="0"+temp
      else
        
        temp="-"+temp
      end
      return temp
    end
    def zero_pad_float(value)
      #pad to 15 digits to right and 30 to left of decimal
      temp=format("%.15f",value.abs).to_s.rjust(45,"0")
      if value>=0
        temp="0"+temp
      else
        
        temp="-"+temp
      end
      return temp
    end
  end
end
