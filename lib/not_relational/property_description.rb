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
    attr_accessor :enum_values
    def self.crypto
      @@crypto||= Configuration.singleton.crypto

    end
    
    def initialize(name,
                   value_type,
                   is_encrypted=false,
                   options={})
      self.name=name
      self.value_type=value_type
      self.is_collection ||= ( options.has_key?(:is_collection) and options[:is_collection])  
      self.is_primary_key=options.has_key?(:is_primary_key)  && options[:is_primary_key]==true
      self.is_encrypted=is_encrypted 
      self.is_encrypted=options[:is_encrypted] if options.has_key?(:is_encrypted)
      self.default_value=options[:default_value]
      if value_type==:enum
        self.enum_values=options[:values]
      end
    end
    
    def is_text?
      return self.value_type==:text
    end

    def assert_valid_value(value)
      x=value_problems(value)
      raise "Invalid value (#{value}) for #{self.name}: #{x}" if x != nil
    end

    
    #return 
    def assert_valid_value(value)
      if self.is_collection
        raise_mismatch( value,"a collection (i.e. implements 'each')") unless value.respond_to?(:each)

        value.each do |sub_val|
          assert_valid_individual_value(sub_val)
        end
        
      else
        return assert_valid_individual_value(value)
      end
    end

    def assert_valid_individual_value(value)
      return if value==nil


      if value_type==:enum
        raise_mismatch( value,"one of [ :#{self.enum_values.join(", :")} ]") unless enum_values.include?(value)
      elsif value_type==:integer
        raise_mismatch( value,"an integer") unless  value.is_a?(Fixnum) || value.is_a(Bignum)
      elsif value_type==:float
        raise_mismatch( value,"a number") unless value.is_a?(Float) || value.is_a?(Fixnum) || value.is_a(Bignum) 
      end

    end

    def raise_mismatch(value,expected)
      raise "#{value} is not valid a value for #{self.name}.  #{self.name} must be #{expected}" 
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
      elsif self.value_type==:date
        result= format_date(value)     
      elsif self.value_type==:boolean
        result= format_boolean(value)     
      elsif self.value_type==:unsigned_integer
        result= format_unsigned_integer(value)    
      elsif self.value_type==:float
        result= format_float(value)

      elsif self.value_type==:enum
        result= format_enum(value)

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
      value=CGI.unescapeHTML(value) if value
      
      if self.value_type==:integer
        return parse_integer(value)
      elsif self.value_type==:date
        return parse_date(value)     
      elsif self.value_type==:boolean
        return parse_boolean(value)     
      elsif self.value_type==:unsigned_integer
        return parse_unsigned_integer(value)    
      elsif self.value_type==:float
        return parse_float(value)
      elsif self.value_type==:enum
        return parse_enum(value)
      elsif self.value_type==:property_bag
        return parse_property_bag(value)
      else
        return value.to_s
      end
      return value
    end
  end
end
