require "active_support"
require "uuid"
require File.dirname(__FILE__) +'/property_description.rb'
require File.dirname(__FILE__) +"/reference.rb"
require File.dirname(__FILE__) +"/index_description.rb"
require File.dirname(__FILE__) +"/lazy_loading_text.rb"
require File.dirname(__FILE__) +"/repository_factory.rb"
require 'active_support/core_ext/string/inflections.rb'
require 'active_support/core_ext/hash/indifferent_access'

class Object
  def nil_or_empty?
    return true if self.nil?
    return self.empty? if self.respond_to? :empty?
    false
  end
end

module NotRelational
  autoload :Inflector, 'active_support/inflector'

  #big ugly class that implements DSL for derived classes
  #all domain model/ data access classes should derive from this class
  #and then use the dsl specify data attributes, keys, and indexes 
  class DomainModel

    @@subclasses = {}
    def self.inherited(subclass)
      @@subclasses[self] ||= []
      @@subclasses[self] << subclass
      subclass.class_eval("

      @index_names=[]

              def self.index_names
                @index_names
              end
              
              @@attribute_descriptions||= Hash.new.with_indifferent_access
              @@non_clob_attribute_names||=[]
              @@clob_attribute_names||=[]
              @@on_destroy_blocks||=[]

              def self.on_destroy_blocks
                @@on_destroy_blocks || []
              end

              def self.attribute_descriptions
                @@attribute_descriptions
              end

              def self.non_clob_attribute_names
                @@non_clob_attribute_names
              end

              def self.clob_attribute_names
                @@clob_attribute_names
              end

              def is_dirty(attribute_name)
                if @attribute_values[attribute_name]!= nil && 
                    @attribute_values[attribute_name].is_a?(LazyLoadingText)
                  return @attribute_values[attribute_name].is_dirty
                elsif @predirt_attribute_values[attribute_name]==nil
                  return !@attribute_values[attribute_name].eql?(self.class.attribute_descriptions[attribute_name].default_value)
                else
                  return !@attribute_values[attribute_name].eql?(@predirt_attribute_values[attribute_name])
                end
              end

              def self.exists?(primary_key)
                return self.find(primary_key)!=nil
              end


              ")
        super

      
    
    end

    
    @@logger=nil
    @@items_to_commit=nil
    @@transaction_depth=0

    # These two attributes will enable primary key bug 
    # fix to be backwards compatible
    attr_accessor :computed_flattened_primary_key_at_load_time
    attr_accessor :sdb_primary_key_at_load_time
    def initialize(options={})
      @predirt_attribute_values=Hash.new.with_indifferent_access
      @attribute_values=Hash.new.with_indifferent_access

      copy_attributes(options)

      @repository_id_at_load_time=options["@@REPOSITORY_ID"]
      @computed_flattened_primary_key_at_load_time=flat_primary_key
    end

    def copy_attributes(hash)
      self.class.attribute_descriptions.each do |attribute_name,description|
        attribute_name=attribute_name.to_sym
        if hash.has_key?(attribute_name) 
          
          value=hash[attribute_name]

          if !description.is_collection && value.respond_to?(:flatten) && value.length==1
            value=value[0]
          end
          
          set_attribute(attribute_name,value)
          
        else

          unless @attribute_values.has_key?(attribute_name)
            @attribute_values[attribute_name]=description.default_value
          end 
        end

      end


    end

    def self.primary_key_attribute_names
      return @primary_key_attribute_names
    end


    def id
      return @attribute_values[:id] if self.class.attribute_descriptions[:id]
      return base.id
    end
    def set_map(keys,values)
      (0..keys.length-1).each do |i|
        key=keys[i]
        value=values[i]
        @attribute_values[key]=value
      end


    end


    def self.index_names
      []
    end

    def self.index(index_name,columns,options={})
      @index_descriptions||={}
      return if self.index_descriptions[index_name]
      is_index_encrypted=@is_encrypted
      is_index_encrypted=options[:is_encrypted] if options.has_key?(:is_encrypted)

      $columns_xxx=columns
      class_eval("

         unless @index_descriptions.has_key?(:#{index_name})

            @index_names << :#{index_name}

            attribute_description=NotRelational::PropertyDescription.new(:#{index_name},:string,{})
                                                                         @index_descriptions[:#{index_name}]=NotRelational::IndexDescription.new(:#{index_name},$columns_xxx,#{is_index_encrypted.to_s})
         end
      ")
      
      getter_params=[]
      finder_code=""
      
      params=[]                                                    
      columns.each do |column|
        if column.respond_to?(:transform)   
          finder_code<< "h[:#{column.name}]=#{column.name.to_s.downcase}\n"
          getter_params<< "@attribute_values[:#{column.source_column}]"
          
          params << "#{column.name.to_s.downcase}"
        else
          finder_code<< "h[:#{column}]=#{column.to_s.downcase}\n"
          getter_params<< "@attribute_values[:#{column}]"
          params << "#{column.to_s.downcase}"
          
        end
        
      end
      find_scope=":all"
      if options[:unique]
        find_scope=":first"
      end

      class_eval "
        def #{index_name}()              
          return	self.class.calculate_#{index_name}(#{getter_params.join(",")})
        end

        def self.calculate_#{index_name}(#{params.join(",")})
            index_description=index_descriptions[:#{index_name}]
            raise(\"index_desciptions[:#{index_name}] does not exist\") unless index_description
            h={}
            #{finder_code}
            index_description.format_index_entry(@@attribute_descriptions,h)
        end
        def self.find_by_#{index_name}(#{params.join(",")},options={})
            options[:params]={:#{index_name}=>self.calculate_#{index_name}(#{params.join(",")})}
            options[:index]=:#{index_name}
            options[:index_value]=self.calculate_#{index_name}(#{params.join(",")})
            find(#{find_scope},options)
        end
                                                                             "
      end #self.index


        @index_descriptions ||={}

      def self.index_descriptions
        @index_descriptions || {}
      end

      def self.is_encrypted?
        return @is_encrypted 
      end

      def self.encrypt_me
        class_eval "@is_encrypted=true"
      end
      def self.property(name,type=:string,options={})
        @is_encrypted||=false
        is_prop_encrypted=@is_encrypted
        is_prop_encrypted=options[:is_encrypted] if options.has_key?(:is_encrypted)
        return if self.attribute_descriptions.has_key?(name)
        
        attribute_description=PropertyDescription.new(name,type,is_prop_encrypted,options)
        self.attribute_descriptions[name] = attribute_description
        @primary_key_attribute_names||=[]
        if attribute_description.is_primary_key 
          @primary_key_attribute_names << name
          pk_code="[:#{@primary_key_attribute_names.join(",:")}]"

          class_eval("
            def self.primary_key_attribute_names
              #{pk_code}
            end
            ")
       end
       if attribute_description.value_type==:text
         clob_attribute_names<< attribute_description.name
       else
         non_clob_attribute_names<< attribute_description.name
       end

     scope=":all"
     if(options[:unique] && options[:unique]==true)
       scope=":first"
     end
     
     class_eval("
    
	   def #{attribute_description.name}=(xvalue)
         set_attribute(:#{attribute_description.name},xvalue)
                     end

     def #{attribute_description.name}?
       get_attribute(:#{attribute_description.name}) 
                   end
   
   def #{attribute_description.name}_is_dirty?
     return @is_dirty[:#{attribute_description.name}] 
                    end
 
 def self.find_by_#{attribute_description.name}(#{attribute_description.name.to_s.downcase},options={})
                                                options[:params]={:#{attribute_description.name}=>#{attribute_description.name.to_s.downcase}}
                                                  find(#{scope},options)
                                                     end
                                                     ")

                                                 
      class_eval("
        def #{attribute_description.name}
          if @attribute_values[:#{attribute_description.name}] == :in_storage
                               @attribute_values[:#{attribute_description.name}] = self.repository.get_text(self.table_name,self.primary_key,:#{attribute_description.name},  self.repository_id_for_updates)
                                               end
                               return @attribute_values[:#{attribute_description.name}] 
                                                      end
                               ")

    if type==:enum
      attribute_name=attribute_description.name.to_s
      options[:values].each do |enum|
        
        class_eval <<-GETTERDONE
        def  is_#{attribute_name}_#{enum.to_s.downcase}?
          #{attribute_name} == :#{enum.to_s}
        end
        
        def  is_#{attribute_name}_#{enum.to_s.downcase}=(val)
          if val
            #{attribute_name} = :#{enum.to_s.upcase}
          elsif self.is_#{attribute_name}_#{enum.to_s.downcase}?
            #{attribute_name} = nil
          end
          
        end
        GETTERDONE

      end
    end
  end    
  def self.belongs_to(domain_class,foreign_key_attribute=nil,accesser_attribute_name=nil,options={})




    foreign_key_attribute ||= "#{domain_class.to_s.downcase}_id".to_sym
    accesser_attribute_name ||=domain_class.to_s.underscore.downcase
    if foreign_key_attribute==:without_prefix
      # #send all attributes and let the other class figure it out}

      class_eval <<-GETTERDONE
        def #{accesser_attribute_name}

          #{module_name+domain_class.to_s}.find(@attribute_values)
        end
        GETTERDONE

        
      elsif foreign_key_attribute==:with_prefix
        # #the column names that start with the name of the other class are the
        # fkeys
        fkeys=[]
        self.class.attribute_descriptions.each do |attribute_name,description|
          if attribute_name.index(domain_class.to_s.downcase)==0
            fkeys<< attribute_name
            fkey_names<< attribute_name.to_s
          end
        end
        index(fkey_names.join("_"),keys)

        class_eval <<-GETTERDONE
	def #{accesser_attribute_name}
      mapped_values={}
      prefix='#{domain_class.to_s.downcase}'
      ['#{fkey_names.join("','")}'].each |key|
        mapped_values[key.splice(prefix.length)]=@attribute_values[key]
    end
    #{module_name+domain_class.to_s}.find(mapped_values)

  end
  GETTERDONE
else
  class_eval <<-GETTERDONE
	def #{accesser_attribute_name}
      #{module_name+domain_class.to_s}.find(self.#{foreign_key_attribute})
	end
    GETTERDONE
    if foreign_key_attribute.is_a?(Array)
      index("#{foreign_key_attribute}_index".to_sym,[foreign_key_attribute])
    end
  end

end
def self.many_to_many(domain_class,
                      through_class,
                      reflecting_key_attributes=nil,
                      foriegn_key_attribute=nil,
                      accesser_attribute_name=nil,
                      options={})
  reflecting_key_attributes ||= primary_key_attribute_names.map{|x|self.name+"_"+x.to_s}
  reflecting_key_attributes =arrayify(reflecting_key_attributes)
  reflecting_array_code="[:"+reflecting_key_attributes.join(",:")+"]"

  accesser_attribute_name ||= domain_class.to_s.underscore.pluralize
  order=""
  if options[:order_by]
    if options[:order]
      order="result=DomainModel.sort_result(result,:#{options[:order_by]},:#{options[:order]})"
    else
      order="result=DomainModel.sort_result(result,:#{options[:order_by]},:ascending)"
    end
  end
  
  
  foriegn_key_attributes=options[:foriegn_key_attribute] || "#{domain_class.to_s.downcase}_id".to_sym
  foriegn_key_attributes=arrayify(foriegn_key_attributes)
  fkey_array_code="[:"+foriegn_key_attributes.join(",:")+"]"

  class_eval <<-XXDONE


	def #{accesser_attribute_name}
      #unless @accessor_cache.has_key? :#{accesser_attribute_name}
      through_results= #{module_name+through_class.to_s}.find(:all,:map=>{:keys=>#{reflecting_array_code},:values=>DomainModel.arrayify(self.primary_key)})
        result=[]
      through_results.each do |through_result|
        item= #{module_name+domain_class.to_s}.find(through_result.#{foriegn_key_attribute}) 
          result<< item if item
      end
      #{order}
      
      #  @accessor_cache[:#{accesser_attribute_name}]=result
      return result
      #end
      #return @accessor_cache[:#{accesser_attribute_name}]
      
	end
    def connect_#{domain_class.to_s.downcase}(#{domain_class.to_s.downcase})
                                              connector=#{module_name+through_class.to_s}.new
                                              connector.set_map(#{fkey_array_code},DomainModel.arrayify(#{domain_class.to_s.downcase}.primary_key))
                                                                connector.set_map(#{reflecting_array_code},DomainModel.arrayify(self.primary_key))
                                                                                  connector.save
                                                                                end
                                                                
                                                                XXDONE
                                                                
                                                                
                                                              end


                                              def DomainModel.transaction
                                                @items_to_commit||=[]
                                                @transaction_depth+=1
                                                begin
                                                  yield
                                                rescue # catch all
                                                  raise $! # rethrow
                                                ensure
                                                  @transaction_depth-=1
                                                end
                                                if @@transaction_depth==0
                                                  @items_to_commit.uniq.each do |item |
                                                    item.save!
                                                  end
                                                  @items_to_commit=[]
                                                end
                                                
                                              end
                                              def DomainModel.sort_result(results,sort_by,order=:ascending)
                                                non_null_results=[]
                                                null_results=[]
                                                results.each do |i|
                                                  sorter_value=i.get_attribute(sort_by)
                                                  if sorter_value
                                                    non_null_results<< i
                                                  else
                                                    null_results<< i
                                                  end
                                                end
                                                sorted_results=non_null_results.sort do |a,b|
                                                  a_val= a.get_sortable_attribute(sort_by)
                                                  b_val= b.get_sortable_attribute(sort_by)
                                                  a_val <=> b_val
                                                end
                                                if order!=:ascending
                                                  sorted_results.reverse!
                                                end
                                                sorted_results.concat( null_results)
                                                sorted_results
                                              end
                                              def get_sortable_attribute(attr_name)
                                                a_val= self.get_attribute(attr_name)
                                                return 0 unless a_val
                                                if a_val.class== Time
                                                  return a_val.to_f
                                                else
                                                  return a_val
                                                end
                                              end
                                              def self.has_many(domain_class,
                                                                reflecting_key_attributes=nil,
                                                                accesser_attribute_name=nil,
                                                                options={})
                                                if reflecting_key_attributes==:without_prefix
                                                  reflecting_key_attributes = primary_key_attribute_names.map{|x|x.to_s}

                                                end

                                                reflecting_key_attributes ||= primary_key_attribute_names.map{|x|self.name.downcase+"_"+x.to_s}
                                                reflecting_key_attributes =arrayify(reflecting_key_attributes)
                                                reflecting_array_code="[:"+reflecting_key_attributes.join(",:")+"]"

                                                accesser_attribute_name ||= domain_class.to_s.underscore.pluralize
                                                order=""
                                                if options[:order_by]
                                                  order="{:order_by=>:#{options[:order_by]}"
                                                end
                                                if options[:order]
                                                  if order.length>0
                                                    order << ","
                                                  else
                                                    order<< "{"
                                                  end
                                                  order<< ":order=>:#{options[:order]}"
                                                end
                                                if order.length==0
                                                  order << "{}"
                                                else
                                                  order<< "}"
                                                end


                                                if options[:dependent]
                                                  
                                                  class_eval <<-XXDONE
          
            on_destroy_blocks<< "#{accesser_attribute_name}.each{|item|item.destroy}"
        XXDONE
                                                end
                                                class_eval <<-XXDONE
      def create_child_#{domain_class.to_s.downcase}(options=nil)

        result=#{module_name+domain_class.to_s}.new(options)
          result.copy_attributes(self.primary_key_hash)
        result
      end
      XXDONE
      #  if options[:tracking]
      #    #add add_xxx method
      #    #add to list of tracker attributes
      #
      #      class_eval <<-XXDONE
      #
      #    @@attribute_descriptions[ :#{accesser_attribute_name}_tracker]=TrackerDescription.new(:#{accesser_attribute_name}_tracker,:#{domain_class},:#{reflecting_key_attribute})
      # # def #{accesser_attribute_name} # 	find_tracked_list(:#{accesser_attribute_name}_tracker,#{domain_class},:#{reflecting_key_attribute})
      # # end
      #        def add_to_#{accesser_attribute_name}(item)
      # # 	item.save!
      #                add_to_tracked_list(:#{accesser_attribute_name}_tracker,#{domain_class.to_s},:#{reflecting_key_attribute},item.primary_key)
      #                item.set_attribute(:#{reflecting_key_attribute},self.primary_key)
      #
      #
      # # end
      #    XXDONE
      #  else
      class_eval <<-XXDONE
	def #{accesser_attribute_name}()


      h={}
      pkey=DomainModel::arrayify(self.primary_key)
      #{reflecting_array_code}.each do |key|
      h[key]=pkey.shift
    end
    result= #{module_name+domain_class.to_s}.find_by_index(h,#{order})
      return result

  end
  XXDONE
  # end
end
def self.AttributeDescription(name)
  return attribute_descriptions[name]
end
def self.ColumnDescription(name)
  return column_descriptions[name]
end
def primary_key

  result=[]
  self.class.primary_key_attribute_names.each do |key_part|
    result<<@attribute_values[key_part ]# !!  #TODO need to translate null booleans into false
  end
  return result[0] if result.length==1
  return result
end
def flat_primary_key()
  key=primary_key
  if key.is_a?( Array)
    flattened_key=""
    key.each do |key_part|
      flattened_key << CGI.escape(key_part.to_s)+"/"
    end
    return flattened_key[0..-2]
  else
    return CGI.escape(key.to_s)
  end

end

def primary_key_hash

  result={}
  self.class.primary_key_attribute_names.each do |key_part|
    result[key_part]=@attribute_values[key_part ]
  end
  return result
end
def primary_key=(value)
  key=DomainModel::arrayify(value)
  self.class.primary_key_attribute_names.each do |key_part|

    @attribute_values[ key_part]=key.shift
  end
end
def method_missing(method_symbol, *arguments) #:nodoc:
  method_name = method_symbol.to_s

  if method_name.length > 1
    
    last_char=method_name[-1..-1]
    
    without_last_char=method_name[0..-2].to_sym
    

    case last_char
    when "="
      
      if @attribute_values.has_key?(without_last_char)
        @attribute_values[without_last_char] = arguments.first
      else
        super
      end
    when "?"
      @attribute_values[without_last_char]
    else

      @attribute_values.has_key?(method_symbol) ? @attribute_values[method_symbol] : super
    end
  else
    #its just one char
    super
  end
end
def index_values
  result={}
  self.class.index_names.each do |name|
    
    result[name]=  self.send("#{name}")
    
  end
  result
end
def set_all_clean
  #  @is_dirty=Hash.new(false)
  @predirt_attribute_values=Hash.new.with_indifferent_access
  @attribute_values.each do |attribute_name,value|

    unless value == nil ||  value.is_a?(LazyLoadingText)
      value=value.clone unless value.is_a?(TrueClass) || value.is_a?(Symbol) || value.is_a?(FalseClass)  || value.is_a?(Numeric)
      @predirt_attribute_values[attribute_name]=value
    end
  end
end

def dirty?
  self.class.attribute_descriptions.values.each do |description|
    return true if is_dirty(description.name)
  end
  false
end


def set_attribute(name,xvalue)
  self.class.attribute_descriptions[name].assert_valid_value(xvalue)

  @attribute_values[name] = xvalue

end

def get_attribute(name)
  @attribute_values[name]
end
def to_s
  result= "#{self.class.table_name}\n"
  attributes.each do |key,value|
    if value.respond_to?(:flatten)
      result<< "\t#{key}: ["
      value.each do |sub_value|
        result<< "'#{sub_value.to_s}'"
      end
      result << "]\n"
    else
      result<< "\t#{key}: #{value.to_s}\n"
    end
  end
  result
  
end
def to_xml
  result= "<#{self.class.table_name}>"
  attributes.each do |key,value|
    if value.respond_to?(:flatten)
      result<< "<#{key}>"
      value.each do |sub_value|
        result<< "<value>#{h sub_value.to_s}</value>"
      end
      result<< "</#{key}>"
    else
      result<< "<#{key}>#{h value.to_s}</#{key}>"
    end
  end
  result<< "</#{self.class.table_name}>"
  result
end

def destroy(options={})
  if self.class.on_destroy_blocks
    self.class.on_destroy_blocks.each do |block|
      instance_eval <<-XXDONE
                    #{block}

          XXDONE

    end
  end
  if self.primary_key
    self.repository(options).destroy(self.table_name,primary_key,repository_id_for_updates)
  end
end
def attributes
  result={}
  # #todo refactor to avoid this copy
  self.class.attribute_descriptions.values.each do |description|
    if !description.is_text? || is_dirty(description.name)
      result[description.name]=@attribute_values[description.name]
    end
  end
  return result
end

def find_tracked_list(tracking_attribute,other_class,reflecting_attribute)
  # #if the attribute has no  value do a query
  list=@attribute_values[tracking_attribute]
  if !list
    list=other_class.query_ids(:params=>{reflecting_attribute=>self.primary_key})
    @attribute_values[tracking_attribute]=list
    self.save!
  end
  
  return other_class.find_list(list)
  
end

def add_to_tracked_list(tracking_attribute,other_class,reflecting_attribute,value)
  list=@attribute_values[tracking_attribute]
  if !list
    list=other_class.query_ids(:params=>{reflecting_attribute=>self.primary_key})
    
  end
  list<< value
  @attribute_values[tracking_attribute]=list.uniq
  
end
def save!(options={})
  save(options)
end

def save(options={})
  if !self.primary_key
    self.primary_key= UUID.generate(:compact)
  end
  
  if @@transaction_depth>0
    # #we are in a transaction.  wait to commit
    @@items_to_commit<< self
    
  else
    if options.has_key?(:expected)
      options=options.merge(:expected => replace_keys_with_descriptions(options[:expected]))
    end
    self.repository(options).save(self.table_name,primary_key,dirty_attributes_value_hash,self.class.index_descriptions,  repository_id_for_updates,options)
    set_all_clean
  end
  
end
def replace_keys_with_descriptions(hash)
  result={}
  hash.keys.each do |k|
    description=self.class.attribute_descriptions[k]
    result[description]=hash[k]
  end
  result
end
def dirty_attributes_value_hash
  
  #     $service.put_attributes(class_object.table_name,item.send(name_column),attributes,true)
  result={}
  # #todo refactor to avoid this copy
  self.class.attribute_descriptions.values.each do |description|
    if is_dirty(description.name)
      value=@attribute_values[description.name]
      result[description]=value
    end
    
    
    
  end
  self.index_values.each do |name,value|
    
    result[self.class.index_descriptions[name]]=value
  end
  result
end
def repository_id_for_updates
  if @repository_id_at_load_time!=nil && self.flat_primary_key==@computed_flattened_primary_key_at_load_time
    #no element of the primary key has change so
    #preserve any buggy flat key that might have been saved by
    #old code
    #        puts "OVERRIDING UPDATE KEY (#{self.flat_primary_key})#{@repository_id_at_load_time}"  if @repository_id_at_load_time!=self.flat_primary_key
    return @repository_id_at_load_time

  end
  return nil
end
def table_name
  return self.class.table_name
end
def DomainModel.table_name
  
  return self.name.split(':').pop
end
#    def find
#
#       attributes=repository.find(self.class.name,self.primary_key,@@non_clob_attribute_names,@@clob_attribute_names)
#       attributes.each do |key,value|
#           @attribute_values[key]=value
#       end
#    end
def repository(options=nil)
  
  if options and options.has_key?(:repository)
    return options[:repository]
  end
  if @repository
    return @repository
  end

  return self.class.repository
end

class << self
  def repository(options={})
    
    if options.has_key?(:repository)
      return options[:repository]
    end
    
    return RepositoryFactory.instance(options)
    
  end
  def find_by_index(values,more_options)
    index_descriptions.each do |name,desc|
      if desc.keys_match?(values)
        options={}
        options[:params]={desc.name=>desc.format_index_entry(self.attribute_descriptions,values)}
        options[:index]=desc.name
        options[:index_value]=desc.format_index_entry(self.attribute_descriptions,values)
        options.merge!(more_options)
        return find(:all,options)
      end
    end
    options={}

    options[:params]={}
    options.merge!(more_options)
    values.each{|key,value|options[:params][key]=value}
    return find_every(options)
  end
  def find(*arguments)
    scope   = arguments.slice!(0)
    options = arguments.slice!(0) || {}
    
    case scope
    when :all   then return find_every(options)
    when :first then return find_one(options)
    else             return find_single(scope, options)
    end
  end
  def find_one(options={})
    options[:limit]=1
    find_every(options).first
  end
  def find_every(options={})
    results=[]
    untyped_results=self.repository.query(self.table_name,attribute_descriptions,options)
    untyped_results.each do |item_attributes|
      results << istantiate(item_attributes,self.repository(options))
    end
    return results

  end
  def find_paged(token=nil,options={})

    results=[]
    untyped_results,token=self.repository.query_with_token(self.table_name,attribute_descriptions,token,options)
    untyped_results.each do |item_attributes|

      results << istantiate(item_attributes,self.repository(options))
    end
    return results,token

  end
  def find_list(primary_keys,options={})
    result=[]
    primary_keys.each do |key|
      item=find_single(key,options)
      result << item if item
    end
    return result
  end

  def count(params=nil)
    return self.repository.count(self.table_name,attribute_descriptions,:params => params)

  end
  
  def destroy_all(options={})
    find(:all,options).each{|x|x.destroy}
  end
  
  def query_ids(options={})
    self.repository.query_ids(self.table_name,attribute_descriptions,options)
  end
  def istantiate(sdb_attributes,repository,repository_id=nil)
    this_result=new(sdb_attributes || {})
    this_result.set_all_clean
    this_result
  end
  def arrayify(x)
    unless x.is_a?(Array)
      x=[x]
    end
    return x

  end
  def find_single(id, options)
    return nil if id==nil
    return nil if id.is_a?(String) && id.length==0
    if id.is_a?(Hash)
      id_as_array=[]
      @primary_key_attribute_names.each do |key_name|
        id_as_array << id[key_name]
      end
      id=id_as_array
    end
    id=arrayify(id)
    attributes=self.repository(options).find_one(self.table_name,id,attribute_descriptions)
    if attributes && attributes.length>0
      @primary_key_attribute_names.each do |key_name|
        attributes[key_name]=id.shift
      end
      attributes[:repository]=self.repository(options)
      return istantiate(attributes,self.repository(options))
    end
    return nil
  end
  def find_recent_with_exponential_expansion(time_column,how_many,options={})
    found=[]
    tries=0
    timespan=options[:timespan_hint] || 60*60*4
    
    params = options[:params] || {}
    
    while found.length<how_many && tries<4
      time=Time.now.gmtime-timespan
      params[time_column]  =AttributeRange.new(:greater_than=>time)
      found= find(:all,:limit=>how_many,:order=>:descending,:order_by => time_column,
                  :params=>params)
      
      tries=tries+1
      timespan=timespan*3
    end
    return found
    
  end

  def all(options={})
    return find_every(options)
  end
end
def self.module_name
  result=""
  result=self.name.slice(0, self.name.rindex(":")+1) if self.name.rindex(":")
  result
end
  end
end
