module NotRelational

  require 'ya2yaml'
  require File.dirname(__FILE__) +'/sdb_formatter.rb'
  require File.dirname(__FILE__) +'/crypto.rb'
  require File.dirname(__FILE__) +'/configuration.rb'
  class PropertyDescription
    include SdbFormatter
    attr_accessor :name 
    attr_accessor :value_type 
    attr_accessor :is_primary_key
    attr_accessor :is_collection
    attr_accessor :is_encrypted
    attr_accessor :default_value
    
    def self.crypto
      @@crypto||= Configuration.singleton.crypto

    end
    
    def initialize(name,type,is_encrypted=false,options={})
      self.name=name
      self.value_type=type
      self.is_collection=(type==:reference_set)
      self.is_collection ||= ( options.has_key?(:is_collection) and options[:is_collection])  
      self.is_primary_key=options.has_key?(:is_primary_key)  && options[:is_primary_key]==true
      self.is_encrypted=is_encrypted 
      self.is_encrypted=options[:is_encrypted] if options.has_key?(:is_encrypted)
      self.default_value=options[:default_value]
    end
    
    def is_text?
      return self.value_type==:text
    end

    def format_for_sdb(value)
      return format_for_sdb_single( value) unless self.is_collection==true
      result=[]
      value.each do |single_value|
        result << format_for_sdb_single( single_value)
      end
      result
    end

    def format_for_sdb_single(value)
      return nil if value == nil && self.value_type!=:boolean
      if self.value_type==:integer
        result= format_integer(value)
      elsif self.value_type==:reference_set
        result= format_reference_set(value)     
      elsif self.value_type==:date
        result= format_date(value)     
      elsif self.value_type==:boolean
        result= format_boolean(value)     
      elsif self.value_type==:unsigned_integer
        result= format_unsigned_integer(value)    
      elsif self.value_type==:float
        result= format_float(value)

      elsif self.value_type==:property_bag
        result= format_property_bag(value)

      else
        result= format_string(value.to_s)
      end
      if self.is_encrypted
        result=PropertyDescription.crypto.encrypt(result)
      end

      result      
    end
    
    def parse_from_sdb( value)
      return parse_from_sdb_single( value) unless self.is_collection==true
      return [] unless value 
      
      result=[]
      value.each do |single_value|
        result << parse_from_sdb_single( single_value)
      end
      result
    end

    def parse_from_sdb_single( value)
      return self.default_value if value==nil 
      
      if is_encrypted
        begin
          value=PropertyDescription.crypto.decrypt(value)
        rescue
          #assume wasn't encrypted originally
        end
      end

      if self.value_type==:integer
        return parse_integer(value)
      elsif self.value_type==:date
        return parse_date(value)     
      elsif self.value_type==:reference_set
        return parse_reference_set(value)     
      elsif self.value_type==:boolean
        return parse_boolean(value)     
      elsif self.value_type==:unsigned_integer
        return parse_unsigned_integer(value)    
      elsif self.value_type==:float
        return parse_float(value)
      elsif self.value_type==:property_bag
        return parse_property_bag(value)
      else
        return value.to_s
      end
      return value
    end
  end
end
