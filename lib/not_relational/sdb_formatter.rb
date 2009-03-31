module NotRelational
 

module SdbFormatter
     def parse_reference_set(value)
            result=YAML::load(value)
            return result if(result.class==Reference)
            return 
    end
    
     def parse_date(value)
        return nil if value==nil 
        if value.is_a? Date
          return value
        end
        if value.is_a? Time
          return value
        end
        return nil if value.length==0
        return Time.at(value.to_f)
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
     def parse_float(value)
      return nil if value==nil 
      return value.to_f
    end
      def parse_unsigned_integer(value)
          return nil if value==nil 
       return value.to_i
    end
   
   def format_reference_set(value)
        value.to_yaml
        
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
     def format_float(value)
       if value==nil 
                return nil
           end
       return zero_pad_float(value)
    end
      def format_unsigned_integer(value)
           if !value
                return nil
           end
       return zero_pad_integer(value)
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
       temp= value.abs.to_s.rjust(30,"0")
      if value>=0
          temp="0"+temp
      else
          
          temp="-"+temp
      end
      return temp
    end
end
end
