# THis class implements access to SDB 222.
# =I am the walrus=
module NotRelational
  $KCODE = 'u'
  require "aws_sdb"
  require "not_relational/storage.rb"
  require File.dirname(__FILE__) +"/memory_repository.rb"
  require File.dirname(__FILE__) +"/domain_model_cache_item.rb"

  require File.dirname(__FILE__) +"/sdb_monkey_patch.rb"
  # THis class implements access to SDB.
  class SdbRepository
    MAX_PAGE_SIZE=250#defined by sdb
    attr_accessor :storage

    def initialize(
        base_domain_name,#MyDevPayApp
        clob_bucket,
        aws_key_id,
        aws_secret_key,
        memcache_servers = nil  ,
        blob_storage=nil,
        use_seperate_domain_per_model=true,
        options={}
                    
      )

      @logger = options[:logger]
      if !@logger
        @logger = Logger.new(STDOUT)
        @logger.level = options[:log_level] || Logger::WARN
      end


    
      @base_domain_name = base_domain_name
      @storage_bucket = clob_bucket
      @memcache_servers = memcache_servers
      @aws_key_id = aws_key_id
      @aws_secret_key = aws_secret_key
      @use_seperate_domain_per_model=use_seperate_domain_per_model
      @storage=blob_storage

      @use_cache=true
      @use_cache=options[:use_cache] if options.has_key?(:use_cache)


      @storage ||= Storage.new(aws_key_id,aws_secret_key,memcache_servers)
      @sdb=AwsSdb::Service.new(:access_key_id=>aws_key_id,:secret_access_key=>aws_secret_key,:url=>"http://sdb.amazonaws.com")
      @session_cache=MemoryRepository.new

    end
    
    def save(table_name, primary_key, attributes,index_descriptions)

      @session_cache.save(table_name,primary_key,attributes,index_descriptions)

      formatted_attributes={}
      attributes.each do |description,value|
        if value || description.value_type==:boolean
          if description.is_text?
            @storage.put(
              @storage_bucket,
              make_storage_key(table_name,primary_key,description.name),
              value.to_s,
              {})
          else
            formatted_attributes[description.name]=description.format_for_sdb(value)
          end
        end
      end
      if !@use_seperate_domain_per_model
        formatted_attributes['metadata%%table_name'] = table_name

      end
      put_attributes(table_name,primary_key, formatted_attributes )
      # put_into_cache(table_name, primary_key, formatted_attributes)
  
    end

    def destroy(table_name, primary_key)
      @session_cache.destroy(table_name,primary_key)
      @sdb.delete_attributes(make_domain_name(table_name),make_cache_key(table_name, primary_key) )
      #TODO destroy text
    end

   
    # result will be an array of hashes. each hash is a set of attributes
    def query(table_name,attribute_descriptions,options)

     @logger.debug "query on table: #{table_name} : #{options.inspect}"

      if options.has_key?(:limit) and !options.has_key?(:order_by)
        session_cache_result=@session_cache.query(table_name,attribute_descriptions,options)
        if options[:limit]==session_cache_result.length
          return session_cache_result
        end
      end
    
      the_query=build_query(table_name, attribute_descriptions, options)
      @logger.debug "the query: #{the_query}"

      max=MAX_PAGE_SIZE
      if options[:limit]
        max=options[:limit].to_i
      end

      page_size=max> MAX_PAGE_SIZE ? MAX_PAGE_SIZE : max
      sdb_result,token=sdb_query_with_attributes(table_name,the_query,page_size)

      while !(token.nil? || token.empty? || sdb_result.length>=max)
        page_size=max- sdb_result.length
        page_size=page_size> MAX_PAGE_SIZE ? MAX_PAGE_SIZE : page_size
        partial_results,token=sdb_query_with_attributes(table_name,the_query,page_size,token)
        sdb_result.concat( partial_results)
      end

      result=[]
      sdb_result.each{|sdb_row|
        primary_key=sdb_row[0]
        sdb_attributes =sdb_row[1]
        attributes =parse_attributes(attribute_descriptions,sdb_attributes)
        if attributes
          result << attributes
        end
      }

      #ordering is handled in sdb now
#      if options and options[:order_by]
#        result.sort! do |a,b|
#          a_value=a[options[:order_by]]
#          b_value=b[options[:order_by]]
#          if options[:order] && options[:order]!=:ascending
#            if !a_value
#              1
#            else
#              if b_value
#                b_value <=> a_value
#              else
#                -1
#              end
#            end
#          else
#            if !b_value
#              1
#            else
#              if a_value
#                a_value <=> b_value
#              else
#                -1
#              end
#            end
#          end
#        end
#      end
      if options[:limit] && result.length>options[:limit]
        result=result[0..(options[:limit]-1)]
      end
      return result
    end
def get_text(table_name,primary_key,clob_name)
      return @storage.get(@storage_bucket,make_storage_key(table_name,primary_key,clob_name))

    end


    def find_one(table_name, primary_key,attribute_descriptions)#, non_clob_attribute_names, clob_attribute_names)
      session_cache_result=@session_cache.find_one(table_name, make_cache_key(table_name,primary_key),attribute_descriptions)
      return session_cache_result if session_cache_result
      #    if @use_cache
      #      yaml=@storage.get(@storage_bucket,make_cache_key(table_name,primary_key))
      #      if yaml
      #        result=YAML::load( yaml)
      #        if result.respond_to?(:non_clob_attributes) && result.non_clob_attributes!=nil
      #          return parse_attributes(attribute_descriptions, result.non_clob_attributes)
      #        end
      #
      #      end
      #    end
      attributes=parse_attributes(attribute_descriptions,sdb_get_attributes(table_name,primary_key))
      if attributes
        # #attributes[:primary_key]=primary_key #put_into_cache(table_name,
        # primary_key, attributes)
      end
   
      attributes
    end

    def create_domain
      20.times do |i|
        begin
          @sdb.create_domain(@base_domain_name)
          return

        rescue  => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
          sleep(i*i)

        end
      end

    end

    def pause
      sleep(3)
    end

    def  clear
      @session_cache.clear
    end

    # can you guess what this does?
    def clear_session_cache
      @session_cache.clear
    end

    
    private

    def make_domain_name(table_name)
      if @use_seperate_domain_per_model
        @base_domain_name+"_"+table_name
      else
        @base_domain_name
      end
    end

    def put_attributes(table_name,primary_key, formatted_attributes,options={})
      20.times do |i|
        begin
          @sdb.put_attributes(make_domain_name(table_name),make_cache_key(table_name,primary_key) , formatted_attributes, true )
          return

        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
          sleep(i*i)
        end
      end

    end

    def sdb_get_attributes(table_name,primary_key)
      
      @logger.debug( "SDB get_attributes #{table_name} : #{primary_key}") if @logger
     
      20.times do |i|
        begin
          return @sdb.get_attributes(make_domain_name(table_name), make_cache_key(table_name,primary_key))
        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
       
          sleep(i*i)
        ensure
         
        end
      end
    
    end
    
#    this method no longer useful since query with attrivutes was introduced to sdb
#    def sdb_query(table_name,query,max,token=nil)
#
#      @logger.debug( "SDB query:#{table_name}(#{max}) : #{query}   #{token}"  ) if @logger
#      #      puts "#{table_name}  #{query}   (#{max}) #{token}"
#      20.times do |i|
#        begin
#          return @sdb.query(make_domain_name(table_name),query,max,token)
#
#        rescue Exception => e
#          s= "#{e.message}\n#{e.backtrace}"
#          @logger.error(s) if @logger
#
#          sleep(i*i)
#        ensure
#
#        end
#      end
#
#    end

    def sdb_query_with_attributes(table_name,query,max,token=nil)

      @logger.debug( "SDB query:#{table_name}(#{max}) : #{query}   #{token}"  ) if @logger
      20.times do |i|
        begin
          return @sdb.query_with_attributes(make_domain_name(table_name),query,max,token)

        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.error(s) if @logger

          sleep(i*i)
        ensure

        end
      end

    end


     def extend_query(query,new_clause)
      if query.length>0
        query << " intersection "
      end

      query << new_clause
    end
    def escape_quotes(value)
      return nil unless value
      value.gsub( "'","\\'")
    end
    def build_query(table_name,attribute_descriptions,options={})


      query=""
      params=nil
      params=options[:params] if options.has_key?(:params)
      params ||= options[:conditions] if options.has_key?(:conditions) and options[:conditions].is_a?(Hash)

      if options.has_key?(:map)
        params||={}
        keys=options[:map][:keys]
        values=options[:map][:values]
        (0..keys.length-1).each do |i|
          key=keys[i]
          value=values[i]
          params[key]=value
        end

      end
      if !@use_seperate_domain_per_model
        extend_query(query," ['metadata%%table_name' = '#{table_name}']")

      end
      if options
        if options.has_key?(:query)
          extend_query(query,"["+options[:query]+"]")
        end
        if params
          params.each do |key,value|
            got_something=false
            if attribute_descriptions.has_key?(key)
              if value==:NOT_NULL
                got_something=true
                extend_query(query," ['#{key}' starts-with '']")
              end
              if value==:NULL or value==nil
                got_something=true
                extend_query(query," not ['#{key}' starts-with '']")
              end
              if value.respond_to?(:less_than) && value.less_than
                got_something=true
                extend_query(query," ['#{key}' < '#{escape_quotes(attribute_descriptions[key].format_for_sdb_single( value.less_than))}']")
              end
              if value.respond_to?(:greater_than) && value.greater_than
                got_something=true
                extend_query(query," ['#{key}' > '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single( value.greater_than))}']")
              end
              if value.respond_to?(:less_than_or_equal_to) && value.less_than_or_equal_to
                got_something=true
                extend_query(query,"['#{key}' <= '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single( value.less_than_or_equal_to))}']")
              end
              if value.respond_to?(:greater_than_or_equal_to) && value.greater_than_or_equal_to
                got_something=true
                extend_query(query," ['#{key}' >= '#{escape_quotes(attribute_descriptions[key].format_for_sdb_single( value.greater_than_or_equal_to))}']")
              end
              if !got_something
                extend_query(query," ['#{key}' = '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single(value))}']")
              end
            else
              # #it must be formatted already.  likely an index
              extend_query(query,"['#{key}' = '#{escape_quotes value}']")
            end
          end
        end
        if options.has_key?(:order_by) && options[:order_by]
          clause=" ['#{options[:order_by]}' starts-with ''] sort '#{options[:order_by]}' "
          if options.has_key?(:order) and ( options[:order]==:descending or options[:order]==:desc)
            clause << " desc "
          end
          extend_query(query,clause)
        end
        if options.has_key?(:conditions) and !options[:conditions].is_a?(Hash)
          options[:conditions].each do |condition|

            extend_query(query,"["+condition.to_sdb_query()+"]")
          end
        end

      end
      return query

    end

#  def put_into_cache(table_name, primary_key, formatted_attributes)
    #      if @use_cache
    #      cacheItem=DomainModelCacheItem.new(table_name, primary_key, formatted_attributes)
    #
    #      yaml=cacheItem.ya2yaml(:syck_compatible => true)
    #
    #      @storage.put(
    #        @storage_bucket,
    #        make_cache_key(table_name,primary_key),
    #        yaml ,
    #        {})
    #    end
    #  end


    
    def parse_attributes(attribute_descriptions,attributes)
      if !attributes || attributes.length==0
        return nil
      end
      parsed_attributes={}
      attribute_descriptions.each do |attribute_name,attribute_description|
        value=attributes[attribute_name.to_sym]
        if !value
          value=attributes[attribute_name]
        end
        # #sdb attributes are often array of one
        if !attribute_description.is_collection && value.respond_to?(:flatten) && value.length==1
          value=value[0]
        end
        parsed_attributes[attribute_name.to_sym]=attribute_description.parse_from_sdb(value)
      end
      parsed_attributes
    end

    
    def flatten_key(key)
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

    def make_cache_key(table_name,primary_key)

      primary_key=flatten_key(primary_key)
      primary_key="#{table_name}/#{primary_key}" unless @use_seperate_domain_per_model
      return primary_key
    end

    def make_storage_key(table_name,primary_key,clob_name)
      return "clobs/#{table_name}/#{flatten_key(primary_key)}/#{clob_name}"
    end

    
  end
end  
