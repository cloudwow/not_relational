module NotRelational

  require File.dirname(__FILE__) +"/memory_storage.rb"

  class MemcacheRepository
    attr_accessor :use_cache #this here just so interface matches sdb repo
    attr_accessor :storage
    def initialize(
        domain_name= nil,
        clob_bucket= nil,
        aws_key_id= nil,
        aws_secret_key= nil,
        memcache_servers = nil ,
        a_storage=nil,
        append_table_to_domain=nil,
        options={}
      )
      options[:memory_only] ||=(aws_key_id==nil)
      @storage||=Storage.new(aws_key_id,aws_secret_key,memcache_servers,[],options)
      @domain_name=domain_name
      @clob_bucket=clob_bucket
    end

    def pause
    end

    def clear_session_cache

    end

    def clear
      
    end

    def save(table_name, primary_key, attributes,index_descriptions)
      key=make_cache_key(table_name,primary_key);
      record={}

      attributes.each do |description,value|
        
          record[description.name]=value
      end
      record["metadata%table_name"]=table_name
      record["metadata%primary_key"]=key
      @storage.put(@clob_bucket,key,record)
    end
    def query_ids(table_name,attribute_descriptions,options)
      raise " not supported for memcache repo"

    end

    def query(table_name,attribute_descriptions,options)
      raise " not supported for memcache repo"
    end
    def find_one(table_name, primary_key,attribute_descriptions)#, non_clob_attribute_names, clob_attribute_names)

      key=make_cache_key(table_name,primary_key)
      @storage.get(@clob_bucket,key)


    end
    def get_clob(table_name,primary_key,clob_name)
      raise " not supported for memcache repo"

    end
    def destroy(table_name, primary_key)
      key=make_cache_key(table_name,primary_key);
      @storage.put(@clob_bucket,key,nil)

    end
    private
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
      return "#{@domain_name}/#{table_name}/#{primary_key}"
    end

  end

end
