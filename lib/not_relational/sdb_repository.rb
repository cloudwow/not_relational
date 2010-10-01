# THis class implements access to SDB 222.
# =I am the walrus=
module NotRelational

  require "aws_sdb"
  require "not_relational/storage.rb"
  require File.dirname(__FILE__) +"/memory_repository.rb"
  require File.dirname(__FILE__) +"/domain_model_cache_item.rb"

  require File.dirname(__FILE__) +"/sdb_monkey_patch.rb"
  # THis class implements access to SDB.
  class SdbRepository  < RepositoryBase
    @@max_page_size = 250 #defined by sdb
    attr_accessor :storage
    attr_accessor :logger
    #    attr_accessor :blob_bucket
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
        @logger = Logger.new(STDERR)
        @logger.level = options[:log_level] || Logger::WARN
      end
      
      @quiet_logger=Logger.new(STDERR)
      @quiet_logger.level=Logger::WARN	
      
      @base_domain_name = base_domain_name
      @blob_bucket = @storage_bucket = clob_bucket
      @memcache_servers = memcache_servers
      @aws_key_id = aws_key_id
      @aws_secret_key = aws_secret_key
      @use_seperate_domain_per_model=use_seperate_domain_per_model
      @storage=blob_storage

      @use_cache=true
      @use_cache=options[:use_cache] if options.has_key?(:use_cache)


      @storage ||= Storage.new(aws_key_id,aws_secret_key,memcache_servers)
      @sdb=AwsSdb::Service.new(:access_key_id=>aws_key_id,:secret_access_key=>aws_secret_key,:url=>"http://sdb.amazonaws.com",:logger => @quiet_logger)
      @session_cache=MemoryRepository.new
      @query_cache={}
      @storage.start_session_cache
    end
    
    def save(table_name, primary_key, attributes,index_descriptions,repository_id=nil)

      repository_id ||=make_repo_key(table_name,primary_key)
      @session_cache.save(table_name,primary_key,attributes,index_descriptions)

      formatted_attributes={}
      attributes.each do |description,value|

        formatted_attributes[description.name]=description.format_for_sdb(value)

        storage_value = description.format_for_storage(value)
        if storage_value
          @storage.put(
                       @storage_bucket,
                       make_storage_key_from_cache_key(table_name,repository_id,description.name),
                       storage_value.to_s,
                       {})
        end

      end
      if !@use_seperate_domain_per_model
        formatted_attributes['metadata%%table_name'] = table_name

      end
      put_attributes(table_name,primary_key, formatted_attributes,repository_id )
      # put_into_cache(table_name, primary_key, formatted_attributes)
      
    end

    def destroy(table_name, primary_key,repository_id=nil)
      @logger.debug  "Destroying #{table_name}.[#{primary_key}]"
      repository_id||=make_repo_key(table_name,primary_key)
      @session_cache.destroy(table_name,primary_key)

      #################
      20.times do |i|
        begin
          with_time_logging("delete_attributes") {

            @sdb.delete_attributes(make_domain_name(table_name),repository_id|| make_repo_key(table_name, primary_key) )
          }
          return
        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
          
          sleep(i*i)
          
        end
      end
      

      ################
      # #TODO destroy text
    end
    def query(table_name,attribute_descriptions,options)
      result,token=query_with_token(table_name,attribute_descriptions,nil,options)
      result
    end
    
    # result will be an array of hashes. each hash is a set of attributes
    def query_with_token(table_name,attribute_descriptions,token,options={})
      token ||= options[:token]
      extra_sdb_params={}
      extra_sdb_params["ConsistentRead"]="true" if options[:consistent_read]
      if options.has_key?(:limit) and !options.has_key?(:order_by) and token==nil
        session_cache_result=@session_cache.query(table_name,attribute_descriptions,options)
        if options[:limit]==session_cache_result.length
          return session_cache_result,nil
        end
      end
      the_query=build_query(table_name, attribute_descriptions, options)

      max=1000000
      if options[:limit]
        max=options[:limit].to_i
      end

      page_size=max> @@max_page_size ? @@max_page_size : max

      query_cache_key=nil
      result=nil
      if token==nil
        query_cache_key=table_name+":"+the_query
        cached_primary_keys=@query_cache[query_cache_key]
        if cached_primary_keys
          result=[]
          cached_primary_keys.each do |key|
            rec=@session_cache.find_one(table_name,key,attribute_descriptions)
            result << rec
          end
        end
      end
      unless result
        if @logger.debug?
          msg="sdb query on table: #{table_name}. "
          msg<< "limit:#{options[:limit]} ," if options.has_key?(:limit)
          if options.has_key?(:conditions)
            c_count=0
            options[:conditions].each do |c|
              msg << c.to_s << ", "
              c_count+=1
              break if c_count>4
            end
          end
          msg << options[:params].inspect if options.has_key?(:params)
          @logger.debug msg
        end

        sdb_result,token=sdb_query_with_attributes(table_name,the_query,page_size,token,extra_sdb_params)

        while !(token.nil? || token.empty? || sdb_result.length>=max)
          @logger.debug  "got #{sdb_result.length} so far. going for more..."
          page_size=max- sdb_result.length
          page_size=page_size> @@max_page_size ? @@max_page_size : page_size
          partial_results,token=sdb_query_with_attributes(table_name,the_query,page_size,token,extra_sdb_params)
          sdb_result.concat( partial_results)
        end

        result=[]
        primary_keys=[]
        sdb_result.each{|sdb_row|
          primary_key=sdb_row[0]
          sdb_attributes =sdb_row[1]
          @logger.debug  "FOUND #{table_name}.[#{primary_key}]"

          attributes =parse_attributes(attribute_descriptions,sdb_attributes)
          attributes["@@REPOSITORY_ID"]=primary_key
          @session_cache.save(table_name,primary_key,attributes)
          primary_keys << primary_key
          if attributes
            result << attributes
          end
        }
        @query_cache[query_cache_key]=primary_keys if query_cache_key
      end
      if options[:limit] && result.length>options[:limit]
        result=result[0..(options[:limit]-1)]
      end
      return result,token
    end
    def get_text(table_name,primary_key,clob_name,repository_id=nil)

      repository_id ||= make_repo_key(table_name,primary_key)
      return @storage.get(@storage_bucket,make_storage_key_from_cache_key(table_name,repository_id,clob_name))

    end


    def find_one(table_name, primary_key,attribute_descriptions,options={})#, non_clob_attribute_names, clob_attribute_names)
      session_cache_result=@session_cache.find_one(
                                                   table_name,
                                                   primary_key,
                                                   attribute_descriptions)
      return session_cache_result if session_cache_result
      #    if @use_cache
      #      yaml=@storage.get(@storage_bucket,make_repo_key(table_name,primary_key))
      #      if yaml
      #        result=YAML::load( yaml)
      #        if result.respond_to?(:non_clob_attributes) && result.non_clob_attributes!=nil
      #          return parse_attributes(attribute_descriptions, result.non_clob_attributes)
      #        end
      #
      #      end
      #    end
      extra_sdb_params={}
      extra_sdb_params["ConsistentRead"]="true" if options[:consistent_read]
      attributes=parse_attributes(attribute_descriptions,sdb_get_attributes(table_name,primary_key,extra_sdb_params))
      if attributes
        # #attributes[:primary_key]=primary_key #put_into_cache(table_name, primary_key, attributes)
        attribute_key_values={}
        attributes.each do |name,value|
        end
        @session_cache.save(table_name,primary_key,attributes)

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
      sleep(0.5)
    end

    def  clear
      @session_cache.clear
      @query_cache={}
      @storage.clear_session_cache
    end

    # can you guess what this does?
    def clear_session_cache
      clear
    end

    
    #    private

    def make_domain_name(table_name)
      if @use_seperate_domain_per_model
        @base_domain_name+"_"+table_name
      else
        @base_domain_name
      end
    end

    def put_attributes(table_name,primary_key, formatted_attributes,repository_id)
      @logger.debug( "SDB put_attributes.  #{table_name} , sdb_id:#{repository_id}") if @logger
      @logger.debug( "\tattributes to put:  #{formatted_attributes.inspect}") if @logger

      return if formatted_attributes.length==0

      20.times do |i|
        begin
          with_time_logging("put_attributes") {

            @sdb.put_attributes(make_domain_name(table_name),repository_id ||   make_repo_key(table_name,primary_key) , formatted_attributes, true )
          }
          return

        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
          sleep(i*i)
        end
      end

    end

    def with_time_logging(title)
      start_time=Time.now

      result=yield
      
      if @logger
        
        elapsed_time=Time.now-start_time
        msg="SDB #{title} elapsed time: #{elapsed_time} seconds"
        if elapsed_time >1.5
          @logger.warn(msg)
        else
          @logger.debug(msg)
        end
      end
      result
    end
    def sdb_get_attributes(table_name,primary_key,extra_sdb_params={})

      domain_name=make_domain_name(table_name)
      repo_key=make_repo_key(table_name,primary_key)
      @logger.debug( "SDB get_attributes.  domain:#{domain_name} , sdb_id:#{repo_key}") if @logger
      20.times do |i|
        begin
          with_time_logging("get_attributes"){
            return @sdb.get_attributes(domain_name, repo_key,extra_sdb_params)
          }

        rescue Exception => e
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s) if @logger
          
          sleep(i*i)

        end
        throw "too many errors"
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

    def sdb_query_with_attributes(table_name,query,max,token=nil,extra_sdb_params={})

      @logger.debug( "SDB query_with_attributes:#{table_name}(#{max}) : #{query}   #{token}"  ) if @logger
      20.times do |i|
        begin
          with_time_logging("query_with_attributes") {
            
            return @sdb.query_with_attributes(make_domain_name(table_name),query,max,token,extra_sdb_params)
          }
        rescue Exception => e
          if e.message =="The specified domain does not exist."
            raise "The SDB domain '#{make_domain_name(table_name)}' does not exist."
            
          else
            s= "#{e.message}\n#{e.backtrace}"
            @logger.error(s) if @logger

            sleep(i*i)
          end
        ensure

        end
      end

    end


    def extend_query(query,new_clause)
      if query.length>0
        query << " AND "
      end

      query << new_clause
    end
    def escape_quotes(value)
      return nil unless value
      #escape slashes too, working with  bizarre ruby need to double escape in gsub
      value.gsub("\\","\\\\\\\\").gsub( "'","\\'")
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
        extend_query(query," `metadata%%table_name` = '#{table_name}'")

      end
      if options
        if options.has_key?(:query)
          extend_query(query,options[:query])
        end
        if params
          params.each do |key,value|
            got_something=false
            if attribute_descriptions.has_key?(key)
              if value==:NOT_NULL
                got_something=true
                extend_query(query," `#{key}`  is not null ")
              end
              if value==:NULL or value==nil
                got_something=true
                extend_query(query," `#{key}` is null ")
              end
              if value.respond_to?(:less_than) && value.less_than
                got_something=true
                extend_query(query," `#{key}` < '#{escape_quotes(attribute_descriptions[key].format_for_sdb_single( value.less_than))}'")
              end
              if value.respond_to?(:greater_than) && value.greater_than
                got_something=true
                extend_query(query," `#{key}` > '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single( value.greater_than))}'")
              end
              if value.respond_to?(:less_than_or_equal_to) && value.less_than_or_equal_to
                got_something=true
                extend_query(query,"`#{key}` <= '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single( value.less_than_or_equal_to))}'")
              end
              if value.respond_to?(:greater_than_or_equal_to) && value.greater_than_or_equal_to
                got_something=true
                extend_query(query," `#{key}` >= '#{escape_quotes(attribute_descriptions[key].format_for_sdb_single( value.greater_than_or_equal_to))}'")
              end
              if !got_something
                extend_query(query," `#{key}` = '#{escape_quotes( attribute_descriptions[key].format_for_sdb_single(value))}'")
              end
            else
              # #it must be formatted already.  likely an index
              extend_query(query,"`#{key}` = '#{escape_quotes value}'")
            end
          end
        end

        if options.has_key?(:conditions) and !options[:conditions].is_a?(Hash)
          options[:conditions].each do |condition|

            extend_query(query,condition.to_sdb_query())
          end
        end
        if options.has_key?(:order_by) && options[:order_by]
          clause=" `#{options[:order_by]}` is not null order by `#{options[:order_by]}` "
          
          if options.has_key?(:order) and ( options[:order]==:descending or options[:order]==:desc)
            clause << " desc "
          end
          extend_query( query ,clause)
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
    #        make_repo_key(table_name,primary_key),
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

    

    def make_storage_key_from_cache_key(table_name,cache_key,clob_name)
      "clobs/#{table_name}/#{cache_key}/#{clob_name}"
    end

    
  end
end  
