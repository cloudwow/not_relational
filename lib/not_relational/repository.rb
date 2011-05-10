module NotRelational
  #kinda sorta Singleton access
  module Repository
    
    def self.repository_instance
      NotRelational::RepositoryFactory.instance
    end
    def self.use_cache=(val)
      repository_instance.use_cache=val
    end
    def self.use_cache
      return repository_instance.use_cache
    end
    
    def self.storage
      return repository_instance.storage
    end    
    def self.query_count
      return repository_instance.query_count
    end
    
    def self.storage
      return repository_instance.storage
    end
    
    
    def self.logger=(val)
      repository_instance.logger=val
    end
    def self.logger
      return repository_instance.logger
    end
    
    def self.pause
      repository_instance.pause
    end
    def self.clear_session_cache
      repository_instance.clear_session_cache
    end

    def self.clear
      repository_instance.clear
    end

    def self.save(table_name, primary_key, attributes,index_descriptions=nil,repository_id=nil)
      repository_instance.save(table_name, primary_key, attributes,index_descriptions,repository_id)
    end

    def self.query_ids(table_name,attribute_descriptions,options)
      repository_instance.query_ids(table_name,attribute_descriptions,options)
    end

    def self.query(table_name,attribute_descriptions,options)
      repository_instance.query(table_name,attribute_descriptions,options)
    end

    def self.find_one(table_name, primary_key,attribute_descriptions)
      repository_instance.find_one(table_name, primary_key,attribute_descriptions)
    end

    def self.get_text(table_name,primary_key,clob_name,repository_id=nil)
      repository_instance.get_text(table_name,primary_key,clob_name,repository_id)
    end

    def self.destroy(table_name, primary_key,repository_id=nil)
      repository_instance.destroy(table_name, primary_key,repository_id)

    end



    def self.cache_write_only=(val)
      repository_instance.cache_write_only=val

    end
    def self.cache_write_only
      repository_instance.cache_write_only
    end
    
    
    def self.persist_cache_peek(key)
      repository_instance.persist_cache_peek(key)
    end
    
    def self.persist_cache_put(key,value)
      repository_instance.persist_cache_put(key,value)
    end
    
    def self.persist_cache_me(key,force_refresh=false,&block)
      repository_instance.persist_cache_me(key,force_refresh,&block)
    end

    def self.short_cache(key,force_refresh=false, &block)
      repository_instance.short_cache(key,force_refresh,&block)
    end
    def self.clear_short_cache(key=nil)
      repository_instance.clear_short_cache(key=nil)
    end
    
  end
end


