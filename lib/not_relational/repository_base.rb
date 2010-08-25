module NotRelational
  class RepositoryBase
    def blob_bucket
      return @blob_bucket || ""
    end
    def blob_bucket=(val)
      @blob_bucket=val
    end

    def make_repo_key(table_name,primary_key)

      if @use_seperate_domain_per_model
        return primary_key 
      else
        flat_primary_key=flatten_key(primary_key)
        return "#{table_name}/#{flat_primary_key}" 
      end
    end

    def cache_write_only=(val)
      @cache_write_only=val
    end

    def cache_write_only
      if  @cache_write_only==nil || @cache_write_only==true
        return true
      else
        return false
      end
    end
    
    def persist_cache_peek(key)
      return nil if cache_write_only
      return short_cache("PersistantCacheCache/"+key) do
        result_yaml= NotRelational::Repository.storage.get(self.blob_bucket,"persistant_cache/"+ key  )
        if result_yaml
          YAML::load( result_yaml)
        else
          nil
        end
      end
    end
    
    def persist_cache_put(key,value)
      NotRelational::Repository.storage.put(self.blob_bucket,"persistant_cache/"+  key,value.to_yaml,{'Content-Type' => 'text/yaml' })
      short_cache_put(key,value)
    end
    
    def persist_cache_me(key,force_refresh=false)

      if force_refresh==true

        result = yield

        persist_cache_put(key,result)
        result
      else
        long_key="PersistantCacheCache/"+key
        return short_cache(long_key) do

          result=persist_cache_peek(key)


          unless result && !cache_write_only
            result = yield

            persist_cache_put(key,result)
          end
          result
        end
      end
    end
    def short_cache_put(key,value)
      @@cache_me_cache ||= {}
      @@cache_me_cache[key ]
    end
    def short_cache(key,force_refresh=false)
      result = nil
      
      @@cache_me_cache ||= {}
      if  @@cache_me_cache.has_key?(key) && !cache_write_only && !force_refresh
        result=@@cache_me_cache[key]
      else
        result =  @@cache_me_cache[key] = yield
      end

      result
    end

    def clear_short_cache(key=nil)
      @@cache_me_cache={}
    end


  end
end
